import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../models/capsule.dart';
import '../models/chat.dart';
import '../repositories/repositories.dart';
import '../services/app_image_cache.dart';
import '../services/image_processor.dart';
import 'firestore_mappers.dart';

/// Chats in the shape the app on main created them, so conversations
/// started there keep working:
///
/// `chats/{uidA}_{uidB}`: participants, lastMessage, lastUpdated, createdAt,
/// lastSenderId. `messages/{id}`: senderId, text, timestamp, status
/// ("sent"/"read"), and for capsules type "capsule", capsuleId, imageUrl.
/// Photos: type "image", imageUrl, imagePath, width, height; the file is
/// `chats/{chatId}/{sender}/{messageId}.jpg` in Storage.
class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ImageProcessor processor = const ImageProcessor(),
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _storageOverride = storage,
       _processor = processor;

  final FirebaseFirestore _db;
  final FirebaseStorage? _storageOverride;
  final ImageProcessor _processor;

  // Looked up on first use (tests without Storage never touch it).
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  static const _batchSize = 450;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _db.collection(FirestorePaths.chats);

  CollectionReference<Map<String, dynamic>> _messages(String chatId) =>
      _chats.doc(chatId).collection(FirestorePaths.messages);

  @override
  Stream<List<Chat>> watchChats(String uid) => _chats
      .where('participants', arrayContains: uid)
      .orderBy('lastUpdated', descending: true)
      .limit(200)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => FirestoreMappers.chat(d.id, d.data()))
            .where((chat) => chat.hasMessages)
            .toList(),
      );

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId, {int limit = 500}) =>
      _messages(chatId)
          .orderBy('timestamp')
          .limitToLast(limit)
          // With metadata: a message written without a connection is
          // "sending" until the server has it (also after a restart).
          .snapshots(includeMetadataChanges: true)
          .map(
            (snap) => snap.docs.map((d) {
              final message = FirestoreMappers.chatMessage(d.id, d.data());
              return d.metadata.hasPendingWrites
                  ? message.withDelivery(MessageDelivery.sending)
                  : message;
            }).toList(),
          )
          .distinct(listEquals);

  @override
  String newMessageId(String chatId) => _messages(chatId).doc().id;

  DocumentReference<Map<String, dynamic>> _typing(String chatId, String uid) =>
      _chats.doc(chatId).collection('typing').doc(uid);

  @override
  Future<void> setTyping(String chatId, String uid, {required bool typing}) =>
      typing
      ? _typing(chatId, uid).set({'at': FieldValue.serverTimestamp()})
      : _typing(chatId, uid).delete();

  @override
  Stream<Map<String, DateTime>> watchTyping(String chatId) => _chats
      .doc(chatId)
      .collection('typing')
      .snapshots()
      .map(
        (snap) => {
          for (final d in snap.docs)
            d.id: switch (d.data()['at']) {
              final Timestamp at => at.toDate(),
              _ => DateTime.now(),
            },
        },
      );

  @override
  Stream<List<Chat>> watchGroups(String uid) => _chats
      .where('members', arrayContains: uid)
      .orderBy('lastUpdated', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => FirestoreMappers.chat(d.id, d.data()))
            .toList(),
      );

  @override
  Future<String> createGroup({
    required String creator,
    required String name,
    required List<String> invitees,
  }) async {
    final ref = _chats.doc('g_${_chats.doc().id}');
    // The group first: the rules let members invite only once it exists.
    await ref.set({
      'members': [creator],
      'name': name.trim(),
      'createdBy': creator,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastUpdated': FieldValue.serverTimestamp(),
    });
    await inviteToGroup(ref.id, by: creator, invitees: invitees);
    return ref.id;
  }

  @override
  Future<void> inviteToGroup(
    String groupId, {
    required String by,
    required List<String> invitees,
  }) {
    final batch = _db.batch();
    for (final uid in invitees.toSet()) {
      if (uid == by) continue;
      batch.set(_chats.doc(groupId).collection('invites').doc(uid), {
        'by': by,
        'at': FieldValue.serverTimestamp(),
      });
    }
    return batch.commit();
  }

  @override
  Future<void> renameGroup(String groupId, String name) =>
      _chats.doc(groupId).update({'name': name.trim()});

  @override
  Future<void> leaveGroup(String groupId, String uid) =>
      _chats.doc(groupId).update({
        'members': FieldValue.arrayRemove([uid]),
        'lastReadAt.$uid': FieldValue.delete(),
      });

  @override
  Future<void> markGroupRead(String groupId, String uid) => _chats
      .doc(groupId)
      .update({'lastReadAt.$uid': FieldValue.serverTimestamp()});

  @override
  Future<void> sendToGroup({
    required String groupId,
    required String from,
    required String text,
    required String messageId,
    MessageReply? replyTo,
    bool forwarded = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final ref = _chats.doc(groupId);
    final batch = _db.batch()
      ..update(ref, {
        'lastMessage': trimmed,
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastSenderId': from,
      })
      ..set(ref.collection(FirestorePaths.messages).doc(messageId), {
        'senderId': from,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        'text': trimmed,
        if (replyTo != null)
          'replyTo': FirestoreMappers.newMessageReply(replyTo),
        if (forwarded) 'forwarded': true,
      });
    return batch.commit();
  }

  @override
  Future<void> sendText({
    required String from,
    required String to,
    required String text,
    required String messageId,
    MessageReply? replyTo,
    bool forwarded = false,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    Future<void> send({required bool quote}) => _send(
      from: from,
      to: to,
      preview: trimmed,
      messageId: messageId,
      message: {
        'text': trimmed,
        if (quote && replyTo != null)
          'replyTo': FirestoreMappers.newMessageReply(replyTo),
        if (forwarded) 'forwarded': true,
      },
    );
    try {
      await send(quote: true);
    } on FirebaseException catch (e) {
      // Rules from before replies: the answer still goes, without its quote.
      if (replyTo == null || e.code != 'permission-denied') rethrow;
      AppLogger.warning('Reply refused with its quote, sending it without');
      await send(quote: false);
    }
  }

  @override
  Future<ChatPhoto> uploadPhoto({
    required String from,
    required String to,
    required String messageId,
    required String localPath,
  }) async {
    final photo = await _processor.chatJpegFromFile(localPath);
    final path = 'chats/${Chat.idBetween(from, to)}/$from/$messageId.jpg';
    final ref = _storage.ref(path);
    // Offline, the message waits in the outbox instead of the upload
    // retrying in the background for the default 10 minutes.
    _storage.setMaxUploadRetryTime(const Duration(seconds: 45));
    try {
      await ref.putData(
        photo.bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    } on FirebaseException catch (e) {
      // A sent photo cannot be replaced (storage.rules): an earlier attempt
      // whose answer was lost already put it there, so that one is used.
      if (e.code != 'unauthorized') rethrow;
      AppLogger.debug('Chat photo already uploaded, using it: $path');
    }
    final url = await ref.getDownloadURL();
    // Shown from the disk cache from now on: never downloaded by the sender.
    await AppImageCache.seed(url, photo.bytes);
    return ChatPhoto(
      url: url,
      path: path,
      width: photo.width,
      height: photo.height,
    );
  }

  @override
  Future<void> sendPhoto({
    required String from,
    required String to,
    required String messageId,
    required ChatPhoto photo,
    String caption = '',
    MessageReply? replyTo,
  }) async {
    final trimmed = caption.trim();
    final text = trimmed.isEmpty ? ChatMessage.photoSign : trimmed;
    Future<void> send({required bool quote}) => _send(
      from: from,
      to: to,
      preview: text,
      messageId: messageId,
      message: {
        'text': text,
        'type': ChatMessageType.image.name,
        'imageUrl': photo.url,
        'imagePath': photo.path,
        'width': photo.width,
        'height': photo.height,
        if (quote && replyTo != null)
          'replyTo': FirestoreMappers.newMessageReply(replyTo),
      },
    );
    try {
      await send(quote: true);
    } on FirebaseException catch (e) {
      if (replyTo == null || e.code != 'permission-denied') rethrow;
      AppLogger.warning(
        'Photo reply refused with its quote, sending it without',
      );
      await send(quote: false);
    }
  }

  @override
  Future<ChatAudio> uploadVoice({
    required String from,
    required String to,
    required String messageId,
    required String localPath,
  }) async {
    final path = 'chats/${Chat.idBetween(from, to)}/$from/$messageId.m4a';
    final ref = _storage.ref(path);
    _storage.setMaxUploadRetryTime(const Duration(seconds: 45));
    try {
      await ref.putFile(
        File(localPath),
        SettableMetadata(contentType: 'audio/mp4'),
      );
    } on FirebaseException catch (e) {
      // A sent recording cannot be replaced (storage.rules): an earlier
      // attempt whose answer was lost already put it there.
      if (e.code != 'unauthorized') rethrow;
      AppLogger.debug('Voice message already uploaded, using it: $path');
    }
    return ChatAudio(url: await ref.getDownloadURL(), path: path);
  }

  @override
  Future<void> sendVoice({
    required String from,
    required String to,
    required String messageId,
    required ChatAudio audio,
    required int durationMs,
    required List<int> waveform,
    MessageReply? replyTo,
  }) async {
    Future<void> send({required bool quote}) => _send(
      from: from,
      to: to,
      preview: ChatMessage.voiceSign,
      messageId: messageId,
      message: {
        'text': ChatMessage.voiceSign,
        'type': ChatMessageType.voice.name,
        'audioUrl': audio.url,
        'audioPath': audio.path,
        'durationMs': durationMs,
        'waveform': waveform,
        if (quote && replyTo != null)
          'replyTo': FirestoreMappers.newMessageReply(replyTo),
      },
    );
    try {
      await send(quote: true);
    } on FirebaseException catch (e) {
      if (replyTo == null || e.code != 'permission-denied') rethrow;
      AppLogger.warning(
        'Voice reply refused with its quote, sending it without',
      );
      await send(quote: false);
    }
  }

  @override
  Future<void> sendCapsule({
    required String from,
    required String to,
    required Capsule capsule,
  }) => _send(
    from: from,
    to: to,
    preview: capsule.title,
    // One chat message per capsule, so a retry cannot post it twice.
    messageId: 'capsule_${capsule.id}',
    message: {
      'text': capsule.title,
      'type': ChatMessageType.capsule.name,
      'capsuleId': capsule.id,
      if (capsule.imageUrl != null) 'imageUrl': capsule.imageUrl,
    },
  );

  /// Writes the message and the chat summary together and counts the
  /// message as unread for [to].
  ///
  /// In a chat this phone already has, one batched write: Firestore keeps it
  /// (also across restarts) and sends it when there is a connection, so
  /// messages written offline go out by themselves. The first message of a
  /// chat needs a transaction (it creates the chat) and so a connection; a
  /// message id that already exists then means an earlier attempt arrived.
  Future<void> _send({
    required String from,
    required String to,
    required String preview,
    required String messageId,
    required Map<String, dynamic> message,
  }) async {
    final chatRef = _chats.doc(Chat.idBetween(from, to));
    final messageRef = chatRef
        .collection(FirestorePaths.messages)
        .doc(messageId);
    final document = {
      'senderId': from,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
      ...message,
    };
    if (await _knownHere(chatRef)) {
      final batch = _db.batch()
        ..update(chatRef, {
          'lastMessage': preview,
          'lastUpdated': FieldValue.serverTimestamp(),
          'lastSenderId': from,
          // The rules check it is exactly one more than before.
          'unreadCounts.$to': FieldValue.increment(1),
        })
        ..set(messageRef, document);
      return batch.commit();
    }
    return _db.runTransaction((tx) async {
      final chat = await tx.get(chatRef);
      if ((await tx.get(messageRef)).exists) return;
      final summary = {
        'lastMessage': preview,
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastSenderId': from,
      };
      if (chat.exists) {
        final unread = FirestoreMappers.chat(
          chat.id,
          chat.data()!,
        ).unreadFor(to);
        tx.update(chatRef, {...summary, 'unreadCounts.$to': unread + 1});
      } else {
        tx.set(chatRef, {
          'participants': [from, to],
          'createdAt': FieldValue.serverTimestamp(),
          'unreadCounts': {to: 1},
          ...summary,
        });
      }
      tx.set(messageRef, document);
    });
  }

  /// Whether this phone's copy of Firestore has the chat (it was loaded or
  /// written here before), without asking the server.
  Future<bool> _knownHere(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      return (await ref.get(const GetOptions(source: Source.cache))).exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> markRead(
    String chatId, {
    required String reader,
    bool receipt = true,
  }) => _chats.doc(chatId).update({
    'unreadCounts.$reader': 0,
    if (receipt) 'lastReadAt.$reader': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> setMessageReaction(
    String chatId,
    String messageId, {
    required String uid,
    ReactionType? type,
  }) => _messages(chatId).doc(messageId).update({
    'reactions.$uid': type?.name ?? FieldValue.delete(),
  });

  @override
  Future<void> deleteMessage(
    String chatId,
    String messageId, {
    String? imagePath,
    String? unreadFor,
  }) async {
    final chatRef = _chats.doc(chatId);
    final newest = await _messages(
      chatId,
    ).orderBy('timestamp', descending: true).limit(2).get();
    final docs = newest.docs;
    final wasNewest = docs.isNotEmpty && docs.first.id == messageId;
    final previous = wasNewest && docs.length > 1
        ? FirestoreMappers.chatMessage(docs[1].id, docs[1].data())
        : null;

    Future<void> commit({required bool exactSummary, required bool drop}) {
      final batch = _db.batch()..delete(_messages(chatId).doc(messageId));
      // Taken back before they read it: one fewer unread for them.
      final unread = drop && unreadFor != null
          ? {'unreadCounts.$unreadFor': FieldValue.increment(-1)}
          : const <String, Object>{};
      if (!wasNewest && unread.isNotEmpty) batch.update(chatRef, unread);
      if (wasNewest) {
        final sentAt = previous?.sentAt;
        batch.update(chatRef, {
          ...previous == null
              // Nothing left: the chat leaves the list, like a cleared one
              // (nothing unread either).
              ? {
                  'lastMessage': '',
                  'lastUpdated': FieldValue.serverTimestamp(),
                  if (unread.isNotEmpty) 'unreadCounts': <String, int>{},
                }
              : exactSummary
              ? {
                  ...unread,
                  'lastMessage': previous.text,
                  'lastUpdated': sentAt == null
                      ? FieldValue.serverTimestamp()
                      : Timestamp.fromDate(sentAt),
                  'lastSenderId': previous.senderId,
                }
              // Rules before `isUndo`: the text only, as a send.
              : {
                  'lastMessage': previous.text,
                  'lastUpdated': FieldValue.serverTimestamp(),
                },
        });
      }
      return batch.commit();
    }

    try {
      await commit(exactSummary: true, drop: true);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      // Rules from before the unread drop, then from before `isUndo`.
      if (unreadFor != null) {
        try {
          AppLogger.warning('Unread drop refused, deleting without it');
          await commit(exactSummary: true, drop: false);
          return _deleteFile(imagePath);
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied') rethrow;
        }
      }
      if (previous == null) rethrow;
      AppLogger.warning('Summary rollback refused, writing the text only');
      await commit(exactSummary: false, drop: false);
    }
    await _deleteFile(imagePath);
  }

  Future<void> _deleteFile(String? imagePath) async {
    // The photo's or recording's file; a server function deletes it too
    // (and for "Clear history"), so a failure here only leaves it for that.
    if (imagePath != null) {
      try {
        await _storage.ref(imagePath).delete();
      } catch (e) {
        AppLogger.debug('Chat photo file not deleted here: $e');
      }
    }
  }

  @override
  Future<void> clearHistory(String chatId) async {
    // Nothing to clear before the first message.
    if (!(await _chats.doc(chatId).get()).exists) return;
    while (true) {
      final page = await _messages(chatId).limit(_batchSize).get();
      if (page.docs.isEmpty) break;
      final batch = _db.batch();
      for (final d in page.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      if (page.docs.length < _batchSize) break;
    }
    await _chats.doc(chatId).update({
      'lastMessage': '',
      'lastUpdated': FieldValue.serverTimestamp(),
      'unreadCounts': <String, int>{},
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/logging/app_logger.dart';
import '../models/capsule.dart';
import '../models/chat.dart';
import '../repositories/repositories.dart';
import 'firestore_mappers.dart';

/// Chats in the shape the app on main created them, so conversations
/// started there keep working:
///
/// `chats/{uidA}_{uidB}`: participants, lastMessage, lastUpdated, createdAt,
/// lastSenderId. `messages/{id}`: senderId, text, timestamp, status
/// ("sent"/"read"), and for capsules type "capsule", capsuleId, imageUrl.
class FirebaseChatRepository implements ChatRepository {
  FirebaseChatRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

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
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => FirestoreMappers.chatMessage(d.id, d.data()))
                .toList(),
          );

  @override
  String newMessageId(String chatId) => _messages(chatId).doc().id;

  @override
  Future<void> sendText({
    required String from,
    required String to,
    required String text,
    required String messageId,
    MessageReply? replyTo,
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

  /// Writes the message and the chat summary in one transaction: creates the
  /// chat on first use and counts the message as unread for [to]. A message
  /// id that already exists means an earlier attempt arrived: nothing to do.
  Future<void> _send({
    required String from,
    required String to,
    required String preview,
    required String messageId,
    required Map<String, dynamic> message,
  }) {
    final chatRef = _chats.doc(Chat.idBetween(from, to));
    final messageRef = chatRef
        .collection(FirestorePaths.messages)
        .doc(messageId);
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
      tx.set(messageRef, {
        'senderId': from,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
        ...message,
      });
    });
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
  Future<void> deleteMessage(String chatId, String messageId) async {
    final chatRef = _chats.doc(chatId);
    final newest = await _messages(
      chatId,
    ).orderBy('timestamp', descending: true).limit(2).get();
    final docs = newest.docs;
    final wasNewest = docs.isNotEmpty && docs.first.id == messageId;
    final previous = wasNewest && docs.length > 1
        ? FirestoreMappers.chatMessage(docs[1].id, docs[1].data())
        : null;

    Future<void> commit({required bool exactSummary}) {
      final batch = _db.batch()..delete(_messages(chatId).doc(messageId));
      if (wasNewest) {
        final sentAt = previous?.sentAt;
        batch.update(
          chatRef,
          previous == null
              // Nothing left: the chat leaves the list, like a cleared one.
              ? {'lastMessage': '', 'lastUpdated': FieldValue.serverTimestamp()}
              : exactSummary
              ? {
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
        );
      }
      return batch.commit();
    }

    try {
      await commit(exactSummary: true);
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied' || previous == null) rethrow;
      AppLogger.warning('Summary rollback refused, writing the text only');
      await commit(exactSummary: false);
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

import 'package:cloud_firestore/cloud_firestore.dart';

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
  Future<void> sendText({
    required String from,
    required String to,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return Future.value();
    return _send(
      from: from,
      to: to,
      preview: trimmed,
      message: {'text': trimmed},
    );
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
    message: {
      'text': capsule.title,
      'type': ChatMessageType.capsule.name,
      'capsuleId': capsule.id,
      if (capsule.imageUrl != null) 'imageUrl': capsule.imageUrl,
    },
  );

  /// Writes the message and the chat summary in one transaction, creating
  /// the chat document on first use.
  Future<void> _send({
    required String from,
    required String to,
    required String preview,
    required Map<String, dynamic> message,
  }) {
    final chatRef = _chats.doc(Chat.idBetween(from, to));
    final messageRef = chatRef.collection(FirestorePaths.messages).doc();
    return _db.runTransaction((tx) async {
      final chat = await tx.get(chatRef);
      final summary = {
        'lastMessage': preview,
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastSenderId': from,
      };
      if (chat.exists) {
        tx.update(chatRef, summary);
      } else {
        tx.set(chatRef, {
          'participants': [from, to],
          'createdAt': FieldValue.serverTimestamp(),
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
  Future<void> markRead(String chatId, {required String sender}) async {
    final unread = await _messages(chatId)
        .where('senderId', isEqualTo: sender)
        .where('status', isEqualTo: 'sent')
        .get();
    final docs = unread.docs;
    for (var i = 0; i < docs.length; i += _batchSize) {
      final batch = _db.batch();
      for (final d in docs.skip(i).take(_batchSize)) {
        batch.update(d.reference, {'status': 'read'});
      }
      await batch.commit();
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
    });
  }
}

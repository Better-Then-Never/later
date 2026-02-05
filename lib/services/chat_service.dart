import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:later/data/models/chat.dart';
import 'package:later/data/models/chat_message.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  static String makeChatId(String uid1, String uid2) {
    if (uid1 == uid2) {
      throw ArgumentError('Cannot create a chat with yourself');
    }
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  String getChatId(String otherUserId) {
    final currentUid = currentUserId;
    if (currentUid == null) {
      throw StateError('User must be logged in to get chat ID');
    }
    return makeChatId(currentUid, otherUserId);
  }

  Future<bool> chatExists(String otherUserId) async {
    final currentUid = currentUserId;
    if (currentUid == null) return false;

    final chatId = makeChatId(currentUid, otherUserId);
    final doc = await _firestore.collection('chats').doc(chatId).get();
    return doc.exists;
  }

  Stream<List<Chat>> getUserChatsStream() {
    final currentUid = currentUserId;
    if (currentUid == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUid)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Chat.fromFirestore(doc))
              .where((chat) => chat.lastMessage.isNotEmpty)
              .toList();
        });
  }

  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }

  Future<void> sendMessage(
    String chatId,
    String text,
    String otherUserId,
  ) async {
    final currentUid = currentUserId;
    if (currentUid == null) {
      throw StateError('User must be logged in to send messages');
    }

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) {
      return;
    }

    final chatRef = _firestore.collection('chats').doc(chatId);
    final messageRef = chatRef.collection('messages').doc();

    await _firestore.runTransaction((transaction) async {
      final chatDoc = await transaction.get(chatRef);

      if (!chatDoc.exists) {
        transaction.set(chatRef, {
          'participants': [currentUid, otherUserId],
          'lastMessage': trimmedText,
          'lastUpdated': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        transaction.update(chatRef, {
          'lastMessage': trimmedText,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      transaction.set(messageRef, {
        'senderId': currentUid,
        'text': trimmedText,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'sent',
      });
    });

    notifyListeners();
  }

  Future<Chat?> getChat(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    if (doc.exists) {
      return Chat.fromFirestore(doc);
    }
    return null;
  }

  String getOtherParticipantId(Chat chat) {
    final currentUid = currentUserId;
    if (currentUid == null) {
      throw StateError('User must be logged in');
    }

    return chat.participants.firstWhere(
      (id) => id != currentUid,
      orElse: () => chat.participants.first,
    );
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final currentUid = currentUserId;
    if (currentUid == null) return;

    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      if (!chatDoc.exists) return;

      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('status', isEqualTo: 'sent')
          .get();

      if (messagesQuery.docs.isEmpty) return;

      final messagesToUpdate = messagesQuery.docs
          .where((doc) => doc.data()['senderId'] != currentUid)
          .toList();

      if (messagesToUpdate.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in messagesToUpdate) {
        batch.update(doc.reference, {'status': 'read'});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Failed to mark messages as read: $e');
    }
  }
}

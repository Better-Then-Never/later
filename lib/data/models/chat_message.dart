import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime? timestamp;
  final String status;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.timestamp,
    this.status = 'sent',
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'sent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
      'status': status,
    };
  }

  bool isSentBy(String userId) => senderId == userId;

  @override
  String toString() {
    return 'ChatMessage(id: $id, senderId: $senderId, text: $text, timestamp: $timestamp, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

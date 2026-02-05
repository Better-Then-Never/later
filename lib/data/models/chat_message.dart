import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, capsule }

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime? timestamp;
  final String status;
  final MessageType type;
  final String? imageUrl;
  final String? capsuleId;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.timestamp,
    this.status = 'sent',
    this.type = MessageType.text,
    this.imageUrl,
    this.capsuleId,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
      status: data['status'] ?? 'sent',
      type: data['type'] == 'capsule' ? MessageType.capsule : MessageType.text,
      imageUrl: data['imageUrl'],
      capsuleId: data['capsuleId'],
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
      'type': type == MessageType.capsule ? 'capsule' : 'text',
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (capsuleId != null) 'capsuleId': capsuleId,
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

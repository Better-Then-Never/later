import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime? lastUpdated;
  final DateTime? createdAt;
  final String? lastSenderId;

  Chat({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    this.lastUpdated,
    this.createdAt,
    this.lastSenderId,
  });

  factory Chat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Chat(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastSenderId: data['lastSenderId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      if (lastSenderId != null) 'lastSenderId': lastSenderId,
    };
  }

  String getOtherParticipantId(String currentUserId) {
    return participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  bool hasParticipant(String userId) => participants.contains(userId);

  @override
  String toString() {
    return 'Chat(id: $id, participants: $participants, lastMessage: $lastMessage, lastUpdated: $lastUpdated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// A conversation between two users (`chats/{uidA}_{uidB}`, uids sorted so
/// both sides compute the same id).
class Chat {
  const Chat({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    this.lastUpdated,
    this.lastSenderId,
  });

  final String id;
  final List<String> participants;

  /// Text of the newest message (a capsule's title for capsules); empty
  /// before the first message and after the history was cleared.
  final String lastMessage;
  final DateTime? lastUpdated;
  final String? lastSenderId;

  /// Longest message text the app sends (the rules enforce it too).
  static const maxMessageLength = 2000;

  /// The id of the conversation between [a] and [b].
  static String idBetween(String a, String b) {
    if (a == b) throw ArgumentError('A chat needs two different users');
    return a.compareTo(b) < 0 ? '${a}_$b' : '${b}_$a';
  }

  /// The other participant, or an empty string for a malformed chat.
  String otherThan(String uid) =>
      participants.firstWhere((p) => p != uid, orElse: () => '');

  bool get hasMessages => lastMessage.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is Chat &&
      other.id == id &&
      other.lastMessage == lastMessage &&
      other.lastUpdated == lastUpdated &&
      other.lastSenderId == lastSenderId &&
      other.participants.length == participants.length &&
      other.participants.every(participants.contains);

  @override
  int get hashCode => Object.hash(id, lastMessage, lastUpdated, lastSenderId);
}

enum ChatMessageType {
  text,
  capsule;

  static ChatMessageType parse(Object? value) =>
      value == 'capsule' ? capsule : text;
}

/// One message (`chats/{chatId}/messages/{id}`).
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.sentAt,
    this.isRead = false,
    this.type = ChatMessageType.text,
    this.capsuleId,
    this.imageUrl,
  });

  final String id;
  final String senderId;
  final String text;

  /// Null while the server timestamp of a message just sent is pending.
  final DateTime? sentAt;
  final bool isRead;
  final ChatMessageType type;

  /// For capsule messages: the shared capsule and its photo.
  final String? capsuleId;
  final String? imageUrl;

  bool get isCapsule => type == ChatMessageType.capsule && capsuleId != null;

  @override
  bool operator ==(Object other) =>
      other is ChatMessage &&
      other.id == id &&
      other.senderId == senderId &&
      other.text == text &&
      other.sentAt == sentAt &&
      other.isRead == isRead &&
      other.type == type &&
      other.capsuleId == capsuleId &&
      other.imageUrl == imageUrl;

  @override
  int get hashCode => Object.hash(id, sentAt, isRead);
}

import 'capsule.dart';

/// A conversation between two users (`chats/{uidA}_{uidB}`, uids sorted so
/// both sides compute the same id).
class Chat {
  const Chat({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    this.lastUpdated,
    this.lastSenderId,
    this.unreadCounts = const {},
    this.lastReadAt = const {},
  });

  final String id;
  final List<String> participants;

  /// Text of the newest message (a capsule's title for capsules); empty
  /// before the first message and after the history was cleared.
  final String lastMessage;
  final DateTime? lastUpdated;
  final String? lastSenderId;

  /// Messages each participant has not read yet. Chats written before this
  /// field existed have none (counted as 0).
  final Map<String, int> unreadCounts;

  /// When each participant last read the chat (read receipts).
  final Map<String, DateTime> lastReadAt;

  int unreadFor(String uid) => unreadCounts[uid] ?? 0;

  DateTime? readAtOf(String uid) => lastReadAt[uid];

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
      _mapEquals(other.unreadCounts, unreadCounts) &&
      _mapEquals(other.lastReadAt, lastReadAt) &&
      other.participants.length == participants.length &&
      other.participants.every(participants.contains);

  @override
  int get hashCode => Object.hash(id, lastMessage, lastUpdated, lastSenderId);
}

enum ChatMessageType {
  text,
  capsule,

  /// A photo (with an optional caption as its text).
  image;

  static ChatMessageType parse(Object? value) => switch (value) {
    'capsule' => capsule,
    'image' => image,
    _ => text,
  };
}

/// A photo of a message, uploaded: its download URL, its file in Storage
/// (`chats/{chatId}/{sender}/{messageId}.jpg`) and its size in pixels.
class ChatPhoto {
  const ChatPhoto({
    required this.url,
    required this.path,
    required this.width,
    required this.height,
  });

  final String url;
  final String path;
  final int width;
  final int height;
}

/// Where a message of this user is on its way to the server.
enum MessageDelivery {
  /// Shown right away, not yet confirmed by the server.
  sending,

  /// The send failed; the user can retry.
  failed,

  /// Stored on the server (every message read from Firestore).
  sent,
}

/// The message a reply quotes: enough to show it without loading it.
class MessageReply {
  const MessageReply({
    required this.id,
    required this.senderId,
    required this.text,
  });

  /// The quote keeps this many characters of the original.
  static const maxText = 140;

  /// [text] replaces the message's own (e.g. "📷 Photo" for a photo).
  factory MessageReply.of(ChatMessage message, {String? text}) {
    final source = text ?? message.text;
    final runes = source.runes;
    return MessageReply(
      id: message.id,
      senderId: message.senderId,
      text: runes.length <= maxText
          ? source
          : '${String.fromCharCodes(runes.take(maxText))}…',
    );
  }

  final String id;
  final String senderId;
  final String text;

  @override
  bool operator ==(Object other) =>
      other is MessageReply &&
      other.id == id &&
      other.senderId == senderId &&
      other.text == text;

  @override
  int get hashCode => Object.hash(id, senderId, text);
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
    this.delivery = MessageDelivery.sent,
    this.replyTo,
    this.reactions = const {},
    this.imagePath,
    this.width,
    this.height,
    this.localPath,
  });

  /// The text of a photo without a caption (older app versions show it).
  static const photoSign = '📷';

  final String id;
  final String senderId;
  final String text;

  /// The message this one answers, quoted.
  final MessageReply? replyTo;

  /// Each participant's reaction, by uid.
  final Map<String, ReactionType> reactions;

  ChatMessage withReaction(String uid, ReactionType? type) => _copy(
    reactions: {
      for (final e in reactions.entries)
        if (e.key != uid) e.key: e.value,
      if (type != null) uid: type,
    },
  );

  /// Null while the server timestamp of a message just sent is pending.
  final DateTime? sentAt;
  final bool isRead;
  final ChatMessageType type;

  /// For capsule messages: the shared capsule and its photo. For photos:
  /// [imageUrl] and the file in Storage ([imagePath]).
  final String? capsuleId;
  final String? imageUrl;
  final String? imagePath;

  /// A photo's size in pixels (its shape before it arrives); null for older
  /// messages and other types.
  final int? width;
  final int? height;

  /// A photo sent from this phone: the picture on the phone, shown until
  /// (and after) the server has it, so it never reloads.
  final String? localPath;
  final MessageDelivery delivery;

  /// Read by the recipient: from the chat's `lastReadAt` (current app) or the
  /// per-message status written by older app versions.
  bool readBy(DateTime? recipientReadAt) {
    if (isRead) return true;
    final at = sentAt;
    return at != null &&
        recipientReadAt != null &&
        !at.isAfter(recipientReadAt);
  }

  ChatMessage withDelivery(MessageDelivery value) => _copy(delivery: value);

  ChatMessage withLocalPath(String? path) => _copy(localPath: path);

  ChatMessage withPhoto(ChatPhoto photo) => _copy(
    imageUrl: photo.url,
    imagePath: photo.path,
    width: photo.width,
    height: photo.height,
  );

  ChatMessage _copy({
    MessageDelivery? delivery,
    Map<String, ReactionType>? reactions,
    String? imageUrl,
    String? imagePath,
    int? width,
    int? height,
    String? localPath,
  }) => ChatMessage(
    id: id,
    senderId: senderId,
    text: text,
    sentAt: sentAt,
    isRead: isRead,
    type: type,
    capsuleId: capsuleId,
    imageUrl: imageUrl ?? this.imageUrl,
    delivery: delivery ?? this.delivery,
    replyTo: replyTo,
    reactions: reactions ?? this.reactions,
    imagePath: imagePath ?? this.imagePath,
    width: width ?? this.width,
    height: height ?? this.height,
    localPath: localPath ?? this.localPath,
  );

  bool get isCapsule => type == ChatMessageType.capsule && capsuleId != null;

  /// A photo message (its picture may still be on its way).
  bool get isPhoto =>
      type == ChatMessageType.image && (imageUrl != null || localPath != null);

  /// What was written with a photo; empty for none.
  String get caption => text == photoSign ? '' : text;

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
      other.imageUrl == imageUrl &&
      other.delivery == delivery &&
      other.replyTo == replyTo &&
      other.imagePath == imagePath &&
      other.width == width &&
      other.height == height &&
      other.localPath == localPath &&
      _mapEquals(other.reactions, reactions);

  @override
  int get hashCode => Object.hash(id, sentAt, isRead, delivery);
}

bool _mapEquals<V>(Map<String, V> a, Map<String, V> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

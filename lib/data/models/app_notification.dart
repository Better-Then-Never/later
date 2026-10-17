enum NotificationType {
  follow,
  capsule,

  /// A chat message (pushes only; never stored as an in-app notification).
  message,
  reply,
  comment,

  /// Someone reacted to the user's capsule (Cloud Functions, social.js).
  reaction,
  friendRequest,
  friendAccepted,

  /// The user unlocked an achievement tier (gamification.js).
  achievement,
  other;

  static NotificationType parse(Object? value) {
    for (final t in values) {
      if (t.name == value) return t;
    }
    return other;
  }
}

/// An in-app notification (`users/{uid}/notifications/{id}`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.fromUserName,
    required this.message,
    required this.isRead,
    this.fromUserId,
    this.fromUserAvatarUrl,
    this.thumbnailImageUrl,
    this.timestamp,
    this.capsuleId,
    this.reaction,
    this.achievementId,
  });

  final String id;
  final NotificationType type;
  final String? fromUserId;
  final String fromUserName;

  /// A network URL, or null. Legacy documents stored asset paths or '' here;
  /// those are normalised to null by the mapper.
  final String? fromUserAvatarUrl;
  final String message;
  final String? thumbnailImageUrl;

  /// Null while the server timestamp is pending.
  final DateTime? timestamp;
  final bool isRead;
  final String? capsuleId;

  /// The emoji of a reaction notification.
  final String? reaction;

  /// Which achievement an achievement notification is about.
  final String? achievementId;

  AppNotification markedRead() => AppNotification(
    id: id,
    type: type,
    fromUserName: fromUserName,
    message: message,
    isRead: true,
    fromUserId: fromUserId,
    fromUserAvatarUrl: fromUserAvatarUrl,
    thumbnailImageUrl: thumbnailImageUrl,
    timestamp: timestamp,
    capsuleId: capsuleId,
    reaction: reaction,
    achievementId: achievementId,
  );
}

enum NotificationType {
  follow,
  capsule,

  /// A chat message (pushes only; never stored as an in-app notification).
  message,
  reply,
  comment,
  other;

  static NotificationType parse(Object? value) {
    for (final t in values) {
      if (t.name == value) return t;
    }
    return other;
  }

  /// Title shown in the list (same mapping as before the refactor).
  String get title => switch (this) {
    NotificationType.follow => 'New Follower',
    NotificationType.capsule => 'New Capsule',
    NotificationType.message => 'New Message',
    NotificationType.reply => 'New Reply',
    NotificationType.comment => 'New Comment',
    NotificationType.other => 'Notification',
  };
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

  String get title => type.title;

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
  );
}

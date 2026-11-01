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

  /// A friend made a capsule with the user (notify.js).
  coAuthor,

  /// A capsule with a date opened (F1, locks.js).
  capsuleOpen,

  /// A place capsule's date came: it waits at its spot (F2, locks.js).
  capsuleReady,

  /// The user is near a capsule they may open there (F4; shown by the
  /// phone itself, app/background_places_main.dart).
  capsuleNearby,

  /// A couple of hours in a new country: "Leave a memory?" (F3; shown by
  /// the phone itself).
  newCountry,
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
    this.capsuleTitle,
    this.placeName,
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

  /// The capsule's title and place ("is open", "is ready").
  final String? capsuleTitle;
  final String? placeName;

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
    capsuleTitle: capsuleTitle,
    placeName: placeName,
  );
}

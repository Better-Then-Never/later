import '../../core/l10n/l10n.dart';
import '../../data/models/app_notification.dart';

/// The filter pills of the notifications page (Profile v4): every kind of
/// notification belongs to Friends, Capsules or Places; "All" shows them all.
enum NotificationFilter {
  all,
  friends,
  capsules,
  places;

  /// The pill [type] is listed under (null: only under "All").
  static NotificationFilter? of(NotificationType type) => switch (type) {
    NotificationType.follow ||
    NotificationType.friendRequest ||
    NotificationType.friendAccepted ||
    NotificationType.message => friends,
    NotificationType.capsule ||
    NotificationType.reply ||
    NotificationType.comment ||
    NotificationType.reaction ||
    NotificationType.coAuthor ||
    NotificationType.capsuleOpen => capsules,
    // A capsule waiting at its spot, one nearby, a new country.
    NotificationType.capsuleReady ||
    NotificationType.capsuleNearby ||
    NotificationType.newCountry => places,
    NotificationType.achievement || NotificationType.other => null,
  };

  bool accepts(AppNotification n) => this == all || of(n.type) == this;

  String label(AppLocalizations l10n) => switch (this) {
    all => l10n.notificationsTabAll,
    friends => l10n.notificationsFilterFriends,
    capsules => l10n.notificationsFilterCapsules,
    places => l10n.notificationsFilterPlaces,
  };
}

/// The two groups of the list: today's notifications and the older ones.
enum NotificationDay {
  today,
  earlier;

  /// The group of something that happened [at] (null: still pending on the
  /// server, so just now).
  static NotificationDay of(DateTime? at, DateTime now) {
    if (at == null) return today;
    final local = at.toLocal();
    final day = now.toLocal();
    return local.year == day.year &&
            local.month == day.month &&
            local.day == day.day
        ? today
        : earlier;
  }

  String label(AppLocalizations l10n) => switch (this) {
    today => l10n.notificationsToday,
    earlier => l10n.notificationsEarlier,
  };
}

/// Who is waiting in the friend requests card: "Dave Miller", "Dave Miller
/// and Erin Moss", then "Dave, Erin and 3 more". [names] are the requesters'
/// names in order; null when none is known yet.
String? friendRequestNames(List<String> names, AppLocalizations l10n) {
  final known = [
    for (final n in names)
      if (n.trim().isNotEmpty) n.trim(),
  ];
  if (known.isEmpty) return null;
  // The others are still loading; the title already says how many.
  if (known.length == 1) return known.first;
  if (names.length == 2) {
    return l10n.notificationsRequestNamesTwo(known[0], known[1]);
  }
  String first(String name) => name.split(RegExp(r'\s+')).first;
  return l10n.notificationsRequestNamesMore(
    first(known[0]),
    first(known[1]),
    names.length - 2,
  );
}

/// When pushes stay silent, in minutes after midnight, local time.
class QuietHours {
  const QuietHours({
    this.enabled = false,
    this.start = 22 * 60,
    this.end = 7 * 60,
  });

  final bool enabled;
  final int start;
  final int end;

  QuietHours copyWith({bool? enabled, int? start, int? end}) => QuietHours(
    enabled: enabled ?? this.enabled,
    start: start ?? this.start,
    end: end ?? this.end,
  );

  @override
  bool operator ==(Object other) =>
      other is QuietHours &&
      other.enabled == enabled &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(enabled, start, end);
}

/// Which pushes the user wants. The Cloud Functions read the same document
/// and send nothing the user turned off (functions/lib/prefs.js).
class NotificationSettings {
  const NotificationSettings({
    this.enabled = true,
    this.messages = true,
    this.follows = true,
    this.capsules = true,
    this.preview = true,
    this.sound = true,
    this.quietHours = const QuietHours(),
    this.utcOffsetMinutes = 0,
  });

  /// Master switch.
  final bool enabled;
  final bool messages;
  final bool follows;
  final bool capsules;

  /// Show the message text in message pushes.
  final bool preview;

  /// Sound and vibration (a silent channel otherwise).
  final bool sound;
  final QuietHours quietHours;

  /// The device's offset from UTC when saved (quiet hours are local time).
  final int utcOffsetMinutes;

  NotificationSettings copyWith({
    bool? enabled,
    bool? messages,
    bool? follows,
    bool? capsules,
    bool? preview,
    bool? sound,
    QuietHours? quietHours,
    int? utcOffsetMinutes,
  }) => NotificationSettings(
    enabled: enabled ?? this.enabled,
    messages: messages ?? this.messages,
    follows: follows ?? this.follows,
    capsules: capsules ?? this.capsules,
    preview: preview ?? this.preview,
    sound: sound ?? this.sound,
    quietHours: quietHours ?? this.quietHours,
    utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationSettings &&
      other.enabled == enabled &&
      other.messages == messages &&
      other.follows == follows &&
      other.capsules == capsules &&
      other.preview == preview &&
      other.sound == sound &&
      other.quietHours == quietHours &&
      other.utcOffsetMinutes == utcOffsetMinutes;

  @override
  int get hashCode => Object.hash(
    enabled,
    messages,
    follows,
    capsules,
    preview,
    sound,
    quietHours,
    utcOffsetMinutes,
  );
}

/// Account-level settings (`users/{uid}/settings/app`). Every field has a
/// default, so a missing document means "everything on".
class UserSettings {
  const UserSettings({
    this.notifications = const NotificationSettings(),
    this.mutedChats = const {},
  });

  final NotificationSettings notifications;

  /// Chats whose messages do not push and do not count in the tab badge.
  final Set<String> mutedChats;

  UserSettings copyWith({
    NotificationSettings? notifications,
    Set<String>? mutedChats,
  }) => UserSettings(
    notifications: notifications ?? this.notifications,
    mutedChats: mutedChats ?? this.mutedChats,
  );

  @override
  bool operator ==(Object other) =>
      other is UserSettings &&
      other.notifications == notifications &&
      other.mutedChats.length == mutedChats.length &&
      other.mutedChats.containsAll(mutedChats);

  @override
  int get hashCode => Object.hash(notifications, mutedChats.length);
}

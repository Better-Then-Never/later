import 'package:flutter/foundation.dart' show listEquals;

import 'capsule.dart';

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
    this.friendRequests = true,
    this.reactions = true,
    this.comments = true,
    this.achievements = true,
    this.news = true,
    this.streakReminder = false,
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
  final bool friendRequests;
  final bool reactions;
  final bool comments;
  final bool achievements;

  /// Announcements from the Later team.
  final bool news;

  /// An evening reminder when the streak is at risk (opt-in).
  final bool streakReminder;

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
    bool? friendRequests,
    bool? reactions,
    bool? comments,
    bool? achievements,
    bool? news,
    bool? streakReminder,
    bool? preview,
    bool? sound,
    QuietHours? quietHours,
    int? utcOffsetMinutes,
  }) => NotificationSettings(
    enabled: enabled ?? this.enabled,
    messages: messages ?? this.messages,
    follows: follows ?? this.follows,
    capsules: capsules ?? this.capsules,
    friendRequests: friendRequests ?? this.friendRequests,
    reactions: reactions ?? this.reactions,
    comments: comments ?? this.comments,
    achievements: achievements ?? this.achievements,
    news: news ?? this.news,
    streakReminder: streakReminder ?? this.streakReminder,
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
      other.friendRequests == friendRequests &&
      other.reactions == reactions &&
      other.comments == comments &&
      other.achievements == achievements &&
      other.news == news &&
      other.streakReminder == streakReminder &&
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
    friendRequests,
    reactions,
    comments,
    achievements,
    news,
    streakReminder,
    preview,
    sound,
    quietHours,
    utcOffsetMinutes,
  );
}

/// Privacy defaults (`privacy` in the settings document).
class PrivacySettings {
  const PrivacySettings({
    this.defaultVisibility = CapsulePrivacy.public,
    this.readReceipts = true,
    this.locationPrecision = LocationPrecision.exact,
    this.contactSuggestions = false,
    this.findByName = true,
    this.findByContacts = false,
  });

  /// What the creation screen starts with.
  final CapsulePrivacy defaultVisibility;

  /// Whether others see when the user has read their messages.
  final bool readReceipts;
  final LocationPrecision locationPrecision;

  /// Whether the app may suggest people from the phone's contacts.
  final bool contactSuggestions;

  /// Whether others find the user by their name (by username always).
  final bool findByName;

  /// Whether people with the user's (verified) email in their contacts may
  /// see them as a suggestion.
  final bool findByContacts;

  PrivacySettings copyWith({
    CapsulePrivacy? defaultVisibility,
    bool? readReceipts,
    LocationPrecision? locationPrecision,
    bool? contactSuggestions,
    bool? findByName,
    bool? findByContacts,
  }) => PrivacySettings(
    defaultVisibility: defaultVisibility ?? this.defaultVisibility,
    readReceipts: readReceipts ?? this.readReceipts,
    locationPrecision: locationPrecision ?? this.locationPrecision,
    contactSuggestions: contactSuggestions ?? this.contactSuggestions,
    findByName: findByName ?? this.findByName,
    findByContacts: findByContacts ?? this.findByContacts,
  );

  @override
  bool operator ==(Object other) =>
      other is PrivacySettings &&
      other.defaultVisibility == defaultVisibility &&
      other.readReceipts == readReceipts &&
      other.locationPrecision == locationPrecision &&
      other.contactSuggestions == contactSuggestions &&
      other.findByName == findByName &&
      other.findByContacts == findByContacts;

  @override
  int get hashCode => Object.hash(
    defaultVisibility,
    readReceipts,
    locationPrecision,
    contactSuggestions,
    findByName,
    findByContacts,
  );
}

/// Account-level settings (`users/{uid}/settings/app`). Every field has a
/// default, so a missing document means "everything on".
class UserSettings {
  const UserSettings({
    this.notifications = const NotificationSettings(),
    this.privacy = const PrivacySettings(),
    this.mutedChats = const {},
    this.pinnedChats = const [],
    this.pinnedFriends = const [],
    this.language,
  });

  /// Most friends pinned at the start of the profile's friends.
  static const maxPinnedFriends = 3;

  /// Friends first on the profile, first pinned first (on every phone).
  final List<String> pinnedFriends;

  /// Most chats kept at the top of the list.
  static const maxPinned = 3;

  /// Chats kept at the top of the list, first pinned first.
  final List<String> pinnedChats;

  final NotificationSettings notifications;
  final PrivacySettings privacy;

  /// Chats whose messages do not push and do not count in the tab badge.
  final Set<String> mutedChats;

  /// The app's language code, for pushes in that language; null = English.
  final String? language;

  UserSettings copyWith({
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    Set<String>? mutedChats,
    List<String>? pinnedChats,
    List<String>? pinnedFriends,
    String? language,
  }) => UserSettings(
    notifications: notifications ?? this.notifications,
    privacy: privacy ?? this.privacy,
    mutedChats: mutedChats ?? this.mutedChats,
    pinnedChats: pinnedChats ?? this.pinnedChats,
    pinnedFriends: pinnedFriends ?? this.pinnedFriends,
    language: language ?? this.language,
  );

  @override
  bool operator ==(Object other) =>
      other is UserSettings &&
      other.notifications == notifications &&
      other.privacy == privacy &&
      other.language == language &&
      other.mutedChats.length == mutedChats.length &&
      other.mutedChats.containsAll(mutedChats) &&
      listEquals(other.pinnedChats, pinnedChats) &&
      listEquals(other.pinnedFriends, pinnedFriends);

  @override
  int get hashCode =>
      Object.hash(notifications, privacy, language, mutedChats.length);
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/l10n/l10n.dart';
import '../models/app_notification.dart';
import '../models/capsule.dart';
import '../models/chat.dart';
import '../models/friend_request.dart';
import '../models/geo_position.dart';
import '../models/social.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';

/// Collection and field names in one place.
abstract final class FirestorePaths {
  static const users = 'users';
  static const usernames = 'usernames';
  static const capsules = 'capsules';
  static const friendRequests = 'friend_requests';
  static const notifications = 'notifications';
  static const fcmTokens = 'fcmTokens';
  static const following = 'following';
  static const followers = 'followers';
  static const blocked = 'blocked';
  static const chats = 'chats';
  static const messages = 'messages';
  static const settings = 'settings';
  static const reactions = 'reactions';
  static const comments = 'comments';
  static const achievements = 'achievements';
  static const announcements = 'announcements';
  static const reports = 'reports';

  /// The one document in users/{uid}/settings.
  static const settingsDoc = 'app';
}

/// Tolerant readers: every mapper accepts legacy shapes and missing fields.
abstract final class FirestoreMappers {
  static DateTime? _date(Object? value) => switch (value) {
    final Timestamp t => t.toDate(),
    final DateTime d => d,
    _ => null,
  };

  static String _string(Object? value, String fallback) =>
      value is String ? value : fallback;

  static String? _nonEmptyString(Object? value) =>
      value is String && value.trim().isNotEmpty ? value : null;

  static Map<String, Object?> _map(Object? value) =>
      value is Map ? value.cast<String, Object?>() : const {};

  static List<String> _stringList(Object? value) =>
      value is Iterable ? value.whereType<String>().toList() : const [];

  /// The Storage emulator's address in emulator builds (bootstrap), whose
  /// download links are plain http; null in real builds.
  static String? storageEmulatorOrigin;

  /// Loop frames are download links: https, or the local emulator's.
  static bool _isFrameUrl(String url) =>
      url.startsWith('https://') ||
      (storageEmulatorOrigin != null && url.startsWith(storageEmulatorOrigin!));

  static UserProfile userProfile(String uid, Map<String, dynamic>? data) {
    if (data == null) return UserProfile.unknown(uid);
    return UserProfile(
      uid: uid,
      name: _string(data['name'], AppL10n.current.commonUnknownUser),
      username: _string(
        data['username'],
        AppL10n.current.commonUnknownUsername,
      ),
      friends: _stringList(data['friends']),
      favorites: _stringList(data['favorites']).toSet(),
      verified: data['verified'] == true,
      followerCount: _count(data['followerCount']),
      followingCount: _count(data['followingCount']),
      showAchievements: _bool(data['showAchievements'], true),
      stats: userStats(_map(data['stats'])),
      about: _string(data['about'], ''),
      searchName: _nonEmptyString(data['nameLower']),
    );
  }

  /// Counters never show below zero (a lost increment must not show -1).
  static int _count(Object? value) =>
      value is num && value > 0 ? value.toInt() : 0;

  static UserStats userStats(Map<String, Object?> s) => UserStats(
    capsules: _count(s['capsules']),
    publicCapsules: _count(s['publicCapsules']),
    loopCapsules: _count(s['loopCapsules']),
    places: _count(s['places']),
    distanceKm: s['distanceKm'] is num && (s['distanceKm'] as num) > 0
        ? (s['distanceKm'] as num).toDouble()
        : 0,
    streakCurrent: _count(s['streakCurrent']),
    streakLongest: _count(s['streakLongest']),
    streakLastDay: _nonEmptyString(s['streakLastDay']),
    reactionsReceived: _count(s['reactionsReceived']),
    commentsWritten: _count(s['commentsWritten']),
    nightCapsules: _count(s['nightCapsules']),
    morningCapsules: _count(s['morningCapsules']),
  );

  static Capsule capsule(String id, Map<String, dynamic> data) {
    final location = data['location'];
    return Capsule(
      id: id,
      // `creatorId` is accepted for documents written by older tooling.
      ownerId: _string(data['ownerId'] ?? data['creatorId'], ''),
      title: _string(data['title'], AppL10n.current.commonUntitled),
      description: _nonEmptyString(data['description']),
      imageUrl: _nonEmptyString(data['imageUrl']),
      // Invalid places (0,0, out of range) are not placed on the map.
      location: location is GeoPoint
          ? switch (GeoPosition(location.latitude, location.longitude)) {
              final GeoPosition p when p.isValid => p,
              _ => null,
            }
          : null,
      privacy: CapsulePrivacy.parse(data['privacy']),
      color: CapsuleColor.parse(data['color']),
      createdAt: _date(data['createdAt']),
      openAt: _date(data['openAt']),
      isScheduled: data['isScheduled'] == true,
      sharedWith: _stringList(data['sharedWith']),
      coAuthors: _stringList(data['coAuthors']),
      capturedAt: _date(data['capturedAt']),
      utcOffsetMinutes: data['utcOffsetMinutes'] is int
          ? data['utcOffsetMinutes'] as int
          : null,
      showAuthor: _bool(data['showAuthor'], true),
      allowComments: _bool(data['allowComments'], true),
      allowReactions: _bool(data['allowReactions'], true),
      locationPrecision: LocationPrecision.parse(data['locationPrecision']),
      frames: _stringList(data['frames']).where(_isFrameUrl).toList(),
      frameDelayMs: data['frameDelayMs'] is int
          ? (data['frameDelayMs'] as int).clamp(80, 2000)
          : Capsule.defaultFrameDelayMs,
      thumbUrl: _nonEmptyString(data['thumbUrl']),
      placeName: _nonEmptyString(data['placeName']),
      reactionCounts: {
        for (final e in _map(data['reactionCounts']).entries)
          if (ReactionType.parse(e.key) case final ReactionType type)
            if (e.value is num && (e.value as num) > 0)
              type: (e.value as num).toInt(),
      },
      reactionTotal: _count(data['reactionTotal']),
      commentCount: _count(data['commentCount']),
    );
  }

  /// Fields a capsule may carry since the 2026 social update; the rules of
  /// older deployments reject them (see [legacyCapsule]).
  static const capsuleFieldsAdded = {
    'capturedAt',
    'utcOffsetMinutes',
    'showAuthor',
    'allowComments',
    'allowReactions',
    'locationPrecision',
    'frames',
    'frameDelayMs',
    'thumbUrl',
    'placeName',
    'coAuthors',
  };

  /// [capsule] without the added fields, for a backend whose rules predate
  /// them (the app retries with this once; DEPLOY.md has the order).
  static Map<String, dynamic> legacyCapsule(Map<String, dynamic> capsule) => {
    for (final e in capsule.entries)
      if (!capsuleFieldsAdded.contains(e.key)) e.key: e.value,
  };

  static Map<String, dynamic> newCapsule(
    CapsuleDraft draft, {
    required String imageUrl,
    List<String> frameUrls = const [],
    String? thumbUrl,
  }) => {
    'ownerId': draft.ownerId,
    'imageUrl': imageUrl,
    'title': draft.title,
    'description': draft.description,
    'location': GeoPoint(draft.location.latitude, draft.location.longitude),
    'privacy': draft.privacy.name,
    'createdAt': FieldValue.serverTimestamp(),
    // True only when the capsule has an open date (was always true, BUG-057).
    'isScheduled': draft.openAt != null,
    'openAt': draft.openAt == null ? null : Timestamp.fromDate(draft.openAt!),
    'color': draft.color.name,
    if (draft.recipientId != null)
      'sharedWith': [draft.ownerId, draft.recipientId!],
    if (draft.capturedAt != null)
      'capturedAt': Timestamp.fromDate(draft.capturedAt!),
    if (draft.utcOffsetMinutes != null)
      'utcOffsetMinutes': draft.utcOffsetMinutes!.clamp(-840, 840),
    // Defaults are left out (absent means true / exact).
    if (!draft.showAuthor) 'showAuthor': false,
    if (draft.coAuthors.isNotEmpty)
      'coAuthors': draft.coAuthors.take(Capsule.maxCoAuthors).toList(),
    if (!draft.allowComments) 'allowComments': false,
    if (!draft.allowReactions) 'allowReactions': false,
    if (draft.locationPrecision != LocationPrecision.exact)
      'locationPrecision': draft.locationPrecision.name,
    if (frameUrls.length > 1) ...{
      'frames': frameUrls,
      'frameDelayMs': draft.frameDelayMs.clamp(80, 2000),
    },
    if (thumbUrl != null) 'thumbUrl': thumbUrl,
    if (draft.placeName case final String place when place.trim().isNotEmpty)
      'placeName': place.length > 200 ? place.substring(0, 200) : place,
  };

  static Chat chat(String id, Map<String, dynamic> data) => Chat(
    id: id,
    participants: _stringList(data['participants']),
    lastMessage: _string(data['lastMessage'], ''),
    lastUpdated: _date(data['lastUpdated']),
    lastSenderId: _nonEmptyString(data['lastSenderId']),
    unreadCounts: {
      for (final e in _map(data['unreadCounts']).entries)
        if (e.value is num) e.key: (e.value as num).toInt(),
    },
    lastReadAt: {
      for (final e in _map(data['lastReadAt']).entries)
        if (_date(e.value) case final DateTime at) e.key: at,
    },
    members: _stringList(data['members']),
    name: _string(data['name'], ''),
  );

  static ChatMessage chatMessage(String id, Map<String, dynamic> data) =>
      ChatMessage(
        id: id,
        senderId: _string(data['senderId'], ''),
        text: _string(data['text'], ''),
        sentAt: _date(data['timestamp']),
        isRead: data['status'] == 'read',
        type: ChatMessageType.parse(data['type']),
        capsuleId: _nonEmptyString(data['capsuleId']),
        imageUrl: _nonEmptyString(data['imageUrl']),
        imagePath: _nonEmptyString(data['imagePath']),
        width: _positiveInt(data['width']),
        height: _positiveInt(data['height']),
        audioUrl: _nonEmptyString(data['audioUrl']),
        audioPath: _nonEmptyString(data['audioPath']),
        durationMs: _positiveInt(data['durationMs']),
        waveform: _waveform(data['waveform']),
        forwarded: data['forwarded'] == true,
        capsuleRef: switch (data['capsuleRef']) {
          {'id': final String id, 'title': final String title}
              when id.isNotEmpty =>
            MessageCapsuleRef(id: id, title: title),
          _ => null,
        },
        replyTo: messageReply(data['replyTo']),
        reactions: messageReactions(data['reactions']),
      );

  static int? _positiveInt(Object? value) =>
      value is num && value > 0 ? value.toInt() : null;

  /// Loudness bars 0-100; anything else is dropped.
  static List<int> _waveform(Object? value) => value is List
      ? [
          for (final v in value)
            if (v is num) v.toInt().clamp(0, 100),
        ]
      : const [];

  /// {uid: type}; unknown types are skipped.
  static Map<String, ReactionType> messageReactions(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final e in value.entries)
        if (e.key is String && ReactionType.parse(e.value) != null)
          e.key as String: ReactionType.parse(e.value)!,
    };
  }

  /// A quoted message; null when missing or malformed.
  static MessageReply? messageReply(Object? value) {
    if (value is! Map) return null;
    final id = _nonEmptyString(value['id']);
    final senderId = _nonEmptyString(value['senderId']);
    final text = value['text'];
    if (id == null || senderId == null || text is! String) return null;
    return MessageReply(id: id, senderId: senderId, text: text);
  }

  static Map<String, Object> newMessageReply(MessageReply reply) => {
    'id': reply.id,
    'senderId': reply.senderId,
    'text': reply.text,
  };

  static bool _bool(Object? value, bool fallback) =>
      value is bool ? value : fallback;

  static int _minutes(Object? value, int fallback) =>
      value is int && value >= 0 && value < 24 * 60 ? value : fallback;

  /// Same defaults as functions/lib/prefs.js.
  static UserSettings userSettings(Map<String, dynamic>? data) {
    if (data == null) return const UserSettings();
    final n = _map(data['notifications']);
    final q = _map(n['quietHours']);
    final p = _map(data['privacy']);
    const d = NotificationSettings();
    const pd = PrivacySettings();
    return UserSettings(
      notifications: NotificationSettings(
        enabled: _bool(n['enabled'], d.enabled),
        messages: _bool(n['messages'], d.messages),
        follows: _bool(n['follows'], d.follows),
        capsules: _bool(n['capsules'], d.capsules),
        preview: _bool(n['preview'], d.preview),
        friendRequests: _bool(n['friendRequests'], d.friendRequests),
        reactions: _bool(n['reactions'], d.reactions),
        comments: _bool(n['comments'], d.comments),
        achievements: _bool(n['achievements'], d.achievements),
        news: _bool(n['news'], d.news),
        streakReminder: _bool(n['streakReminder'], d.streakReminder),
        sound: _bool(n['sound'], d.sound),
        quietHours: QuietHours(
          enabled: _bool(q['enabled'], d.quietHours.enabled),
          start: _minutes(q['start'], d.quietHours.start),
          end: _minutes(q['end'], d.quietHours.end),
        ),
        utcOffsetMinutes: n['utcOffsetMinutes'] is int
            ? n['utcOffsetMinutes'] as int
            : d.utcOffsetMinutes,
      ),
      privacy: PrivacySettings(
        defaultVisibility: CapsulePrivacy.parse(
          p['defaultVisibility'],
          fallback: pd.defaultVisibility,
        ),
        readReceipts: _bool(p['readReceipts'], pd.readReceipts),
        locationPrecision: LocationPrecision.parse(p['locationPrecision']),
        contactSuggestions: _bool(
          p['contactSuggestions'],
          pd.contactSuggestions,
        ),
        findByName: _bool(p['findByName'], pd.findByName),
        findByContacts: _bool(p['findByContacts'], pd.findByContacts),
      ),
      mutedChats: _stringList(data['mutedChats']).toSet(),
      pinnedChats: _stringList(data['pinnedChats']),
      pinnedFriends: _stringList(data['pinnedFriends']),
      language: _nonEmptyString(data['language']),
    );
  }

  static Map<String, dynamic> notificationSettings(NotificationSettings n) => {
    'enabled': n.enabled,
    'messages': n.messages,
    'follows': n.follows,
    'capsules': n.capsules,
    'friendRequests': n.friendRequests,
    'reactions': n.reactions,
    'comments': n.comments,
    'achievements': n.achievements,
    'news': n.news,
    'streakReminder': n.streakReminder,
    'preview': n.preview,
    'sound': n.sound,
    'quietHours': {
      'enabled': n.quietHours.enabled,
      'start': n.quietHours.start,
      'end': n.quietHours.end,
    },
    'utcOffsetMinutes': n.utcOffsetMinutes,
  };

  /// Notification switches added with the 2026 social update.
  static const notificationKeysAdded = {
    'friendRequests',
    'reactions',
    'comments',
    'achievements',
    'news',
    'streakReminder',
  };

  static Map<String, dynamic> privacySettings(PrivacySettings p) => {
    'defaultVisibility': p.defaultVisibility.name,
    'readReceipts': p.readReceipts,
    'locationPrecision': p.locationPrecision.name,
    'contactSuggestions': p.contactSuggestions,
    'findByName': p.findByName,
    'findByContacts': p.findByContacts,
  };

  static CapsuleReaction? reaction(String uid, Map<String, dynamic> data) {
    final type = ReactionType.parse(data['type']);
    if (type == null) return null;
    return CapsuleReaction(uid: uid, type: type, at: _date(data['updatedAt']));
  }

  static CapsuleComment comment(
    String capsuleId,
    String id,
    Map<String, dynamic> data,
  ) => CapsuleComment(
    id: id,
    capsuleId: capsuleId,
    authorId: _string(data['authorId'], ''),
    text: _string(data['text'], ''),
    createdAt: _date(data['createdAt']),
    replyTo: _nonEmptyString(data['replyTo']),
  );

  static Map<String, dynamic> newComment({
    required String authorId,
    required String text,
    String? replyTo,
  }) => {
    'authorId': authorId,
    'text': text,
    'createdAt': FieldValue.serverTimestamp(),
    if (replyTo != null) 'replyTo': replyTo,
  };

  static UnlockedAchievement achievement(
    String id,
    Map<String, dynamic> data,
  ) => UnlockedAchievement(
    id: id,
    tier: data['tier'] is int ? data['tier'] as int : 0,
    tiers: data['tiers'] is int ? data['tiers'] as int : 1,
    value: data['value'] is num ? data['value'] as num : 0,
    unlockedAt: _date(data['unlockedAt']),
  );

  static Announcement announcement(String id, Map<String, dynamic> data) {
    Map<String, String> texts(Object? value) => {
      for (final e in _map(value).entries)
        if (e.value case final String text when text.trim().isNotEmpty)
          e.key: text,
    };
    return Announcement(
      id: id,
      title: texts(data['title']),
      body: texts(data['body']),
      createdAt: _date(data['createdAt']),
    );
  }

  static FriendRequest friendRequest(Map<String, dynamic> data) =>
      FriendRequest(
        fromUserId: _string(data['fromUserId'], ''),
        toUserId: _string(data['toUserId'], ''),
        status: FriendRequestStatus.parse(data['status']),
        createdAt: _date(data['createdAt']),
      );

  static AppNotification notification(String id, Map<String, dynamic> data) {
    String? url(Object? value) {
      final s = _nonEmptyString(value);
      // Legacy documents stored local asset paths; only real URLs are kept.
      return s != null && (s.startsWith('http://') || s.startsWith('https://'))
          ? s
          : null;
    }

    return AppNotification(
      id: id,
      type: NotificationType.parse(data['type']),
      fromUserId: _nonEmptyString(data['fromUserId']),
      // Newer notifications store only the sender's id (the app looks the
      // name up); without a sender it comes from the app itself.
      fromUserName: _string(
        data['fromUserName'],
        data['fromUserId'] is String ? '' : AppL10n.current.appName,
      ),
      fromUserAvatarUrl: url(data['fromUserAvatar']),
      message: _string(data['message'], ''),
      thumbnailImageUrl: url(data['thumbnailImage']),
      timestamp: _date(data['timestamp']),
      isRead: data['isRead'] == true,
      capsuleId: _nonEmptyString(data['capsuleId']),
      reaction: ReactionType.parse(data['reaction'])?.emoji,
      achievementId: _nonEmptyString(data['achievementId']),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';
import '../models/capsule.dart';
import '../models/chat.dart';
import '../models/friend_request.dart';
import '../models/geo_position.dart';
import '../models/user_profile.dart';

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

  static UserProfile userProfile(String uid, Map<String, dynamic>? data) {
    if (data == null) return UserProfile.unknown(uid);
    return UserProfile(
      uid: uid,
      name: _string(data['name'], 'Unknown'),
      username: _string(data['username'], 'unknown'),
      friends: _stringList(data['friends']),
      favorites: _stringList(data['favorites']).toSet(),
    );
  }

  static Capsule capsule(String id, Map<String, dynamic> data) {
    final location = data['location'];
    return Capsule(
      id: id,
      // `creatorId` is accepted for documents written by older tooling.
      ownerId: _string(data['ownerId'] ?? data['creatorId'], ''),
      title: _string(data['title'], 'Untitled'),
      description: _nonEmptyString(data['description']),
      imageUrl: _nonEmptyString(data['imageUrl']),
      location: location is GeoPoint
          ? GeoPosition(location.latitude, location.longitude)
          : null,
      privacy: CapsulePrivacy.parse(data['privacy']),
      color: CapsuleColor.parse(data['color']),
      createdAt: _date(data['createdAt']),
      openAt: _date(data['openAt']),
      isScheduled: data['isScheduled'] == true,
      sharedWith: _stringList(data['sharedWith']),
    );
  }

  static Map<String, dynamic> newCapsule(
    CapsuleDraft draft, {
    required String imageUrl,
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
      );

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
      fromUserName: _string(data['fromUserName'], 'System'),
      fromUserAvatarUrl: url(data['fromUserAvatar']),
      message: _string(data['message'], ''),
      thumbnailImageUrl: url(data['thumbnailImage']),
      timestamp: _date(data['timestamp']),
      isRead: data['isRead'] == true,
      capsuleId: _nonEmptyString(data['capsuleId']),
    );
  }
}

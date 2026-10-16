import 'dart:typed_data';

import '../models/app_notification.dart';
import '../models/capsule.dart';
import '../models/friend_request.dart';
import '../models/user_profile.dart';

/// Result of a Google sign-in, or null when the user cancelled.
class SocialSignInResult {
  const SocialSignInResult({
    required this.uid,
    required this.email,
    required this.displayName,
  });

  final String uid;
  final String email;
  final String displayName;
}

/// The only gateway to Firebase Auth.
abstract interface class AuthRepository {
  Stream<String?> uidChanges();
  String? get currentUid;
  String? get currentEmail;

  Future<void> signInWithEmail(String email, String password);
  Future<String> createAccount(String email, String password);
  Future<SocialSignInResult?> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> updateDisplayName(String name);

  /// Deletes the account that was just created when the profile could not be
  /// written (signup rollback).
  Future<void> deleteCurrentUser();
  Future<void> signOut();
}

abstract interface class UserRepository {
  Stream<UserProfile?> watchProfile(String uid);
  Future<UserProfile?> getProfile(String uid);

  /// Batched lookup (`whereIn` chunks); unknown uids are omitted.
  Future<Map<String, UserProfile>> getProfiles(Iterable<String> uids);

  Future<bool> isUsernameTaken(String username);

  /// Creates `users/{uid}` and reserves `usernames/{username}` atomically.
  /// Throws a ValidationFailure when the username is taken.
  Future<void> createProfile({
    required String uid,
    required String name,
    required String username,
  });

  Future<void> updateName(String uid, String name);
  Future<void> changeUsername(String uid, String newUsername);

  /// Prefix search on lower-case usernames, bounded by [limit].
  Future<List<UserProfile>> searchByUsername(String prefix, {int limit});

  Future<void> setFavorite(String uid, String capsuleId, bool favorite);
}

abstract interface class FriendsRepository {
  Stream<List<FriendRequest>> watchOutgoingPending(String uid);
  Stream<List<FriendRequest>> watchIncomingPending(String uid);
  Future<void> sendRequest({required String from, required String to});
  Future<void> cancelRequest({required String from, required String to});
  Future<void> acceptRequest({required String from, required String to});
  Future<void> rejectRequest({required String from, required String to});
  Future<void> removeFriend({required String me, required String friend});

  Future<bool> isFollowing({required String me, required String target});
  Future<void> follow({
    required String me,
    required String target,
    required String myUsername,
  });
  Future<void> unfollow({required String me, required String target});
}

abstract interface class CapsuleRepository {
  Stream<List<Capsule>> watchOwn(String uid);

  /// Friends-only capsules of [friendIds] (chunked `whereIn`).
  Stream<List<Capsule>> watchFriends(List<String> friendIds);

  /// Public capsules whose latitude is within [minLat]..[maxLat].
  Stream<List<Capsule>> watchPublicInBand(
    double minLat,
    double maxLat, {
    int limit,
  });

  Future<Capsule> create(CapsuleDraft draft);
  Future<void> delete(Iterable<Capsule> capsules);
}

abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watch(String uid, {int limit});
  Future<void> markRead(String uid, Iterable<String> ids);
  Future<void> delete(String uid, Iterable<String> ids);
  Future<void> createFollowNotification({
    required String targetUid,
    required String fromUid,
    required String fromUserName,
  });
}

abstract interface class PushTokenRepository {
  Future<void> saveToken(String uid, String token, String platform);
  Future<void> deleteToken(String uid, String token);
}

enum ProfileImageKind { profile, background }

abstract interface class ImageStorageRepository {
  /// Download URL or null when the user has no such image.
  Future<String?> imageUrl(String uid, ProfileImageKind kind, {bool small});
  Future<void> uploadProfileImage(String uid, Uint8List bytes);
  Future<void> uploadBackgroundImage(String uid, Uint8List bytes);
  Future<void> deleteImage(String uid, ProfileImageKind kind);
}

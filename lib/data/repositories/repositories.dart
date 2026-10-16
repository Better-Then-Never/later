import 'dart:typed_data';

import '../models/app_notification.dart';
import '../models/capsule.dart';
import '../models/chat.dart';
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

  /// Users [uid] blocked (`users/{uid}/blocked/{other}`).
  Stream<Set<String>> watchBlocked(String uid);
  Future<void> block({required String me, required String other});
  Future<void> unblock({required String me, required String other});

  /// Whether [other] blocked [me].
  Future<bool> isBlockedBy({required String me, required String other});
}

/// Two-person chats (`chats/{chatId}` with a `messages` subcollection).
abstract interface class ChatRepository {
  /// Chats of [uid] that have messages, most recently active first.
  Stream<List<Chat>> watchChats(String uid);

  /// Messages of [chatId], oldest first (the newest [limit]).
  Stream<List<ChatMessage>> watchMessages(String chatId, {int limit});

  /// A new message id, made on the device: the message can be shown before
  /// the server has it, and a retry with the same id cannot duplicate it.
  String newMessageId(String chatId);

  /// Sends [text] as message [messageId] from [from] to [to], creating the
  /// chat on first use and counting it as unread for [to]. Sending an id that
  /// already arrived does nothing.
  Future<void> sendText({
    required String from,
    required String to,
    required String text,
    required String messageId,
  });

  /// Posts [capsule] (already shared with [to]) into the chat.
  Future<void> sendCapsule({
    required String from,
    required String to,
    required Capsule capsule,
  });

  /// [reader] has read [chatId]: their unread count goes to 0 and their read
  /// receipt to now, in one write.
  Future<void> markRead(String chatId, {required String reader});

  /// Deletes every message of [chatId], for both participants.
  Future<void> clearHistory(String chatId);
}

abstract interface class CapsuleRepository {
  Stream<List<Capsule>> watchOwn(String uid);

  /// One capsule, or null when it does not exist or is not visible.
  Future<Capsule?> getById(String id);

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

import 'dart:typed_data';

import '../models/app_notification.dart';
import '../models/capsule.dart';
import '../models/chat.dart';
import '../models/friend_request.dart';
import '../models/social.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';

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

  /// Whether the signed-in user has a password (email accounts). Google-only
  /// accounts confirm their identity with Google instead.
  bool get hasPassword;

  /// Confirms the signed-in user's identity right before a sensitive change
  /// (Firebase requires a recent sign-in): with [password] for email
  /// accounts, with the Google account picker otherwise. Returns false when
  /// the user cancelled the picker; throws an AuthFailure on a wrong
  /// password or a different Google account.
  Future<bool> reauthenticate({String? password});

  /// Call [reauthenticate] first.
  Future<void> updatePassword(String newPassword);

  /// Sends a confirmation link to [newEmail]; the sign-in email changes when
  /// the user opens it. Call [reauthenticate] first.
  Future<void> requestEmailChange(String newEmail);

  /// Deletes the signed-in Auth account for good; a Cloud Function then
  /// removes its data (functions/lib/account.js). Call [reauthenticate]
  /// first.
  Future<void> deleteAccount();
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

  /// Whether friends may see [uid]'s achievements.
  Future<void> setShowAchievements(String uid, bool show);
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

  /// [reader] has read [chatId]: their unread count goes to 0 and, with
  /// [receipt], their read receipt to now, in one write.
  Future<void> markRead(
    String chatId, {
    required String reader,
    bool receipt = true,
  });

  /// Deletes every message of [chatId], for both participants.
  Future<void> clearHistory(String chatId);
}

abstract interface class CapsuleRepository {
  Stream<List<Capsule>> watchOwn(String uid);

  /// One capsule, or null when it does not exist or is not visible.
  Future<Capsule?> getById(String id);

  /// One capsule, live (counters move as people react and comment); null
  /// when it is deleted or not visible.
  Stream<Capsule?> watchById(String id);

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

/// Reactions, comments, reports, achievements and announcements.
abstract interface class SocialRepository {
  /// Everyone's reactions on [capsuleId], newest first.
  Stream<List<CapsuleReaction>> watchReactions(String capsuleId, {int limit});

  /// The reaction of [uid] on [capsuleId], or null.
  Stream<ReactionType?> watchMyReaction(String capsuleId, String uid);

  /// Sets (or with null removes) the reaction of [uid].
  Future<void> setReaction(String capsuleId, String uid, ReactionType? type);

  /// Comments on [capsuleId], oldest first (the newest [limit]).
  Stream<List<CapsuleComment>> watchComments(String capsuleId, {int limit});

  Future<void> addComment(
    String capsuleId, {
    required String authorId,
    required String text,
    String? replyTo,
  });

  /// The author or the capsule's owner may delete a comment.
  Future<void> deleteComment(String capsuleId, String commentId);

  /// Sends a report to the Later team; nobody else can read it.
  Future<void> report({
    required String reporterId,
    required ReportTarget target,
    required String targetPath,
    required ReportReason reason,
    String? details,
  });

  /// Achievements [uid] unlocked (own, or a friend's when they share them).
  Stream<List<UnlockedAchievement>> watchAchievements(String uid);

  /// Messages from the Later team, newest first.
  Stream<List<Announcement>> watchAnnouncements({int limit});
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

/// Account-level settings (`users/{uid}/settings/app`).
abstract interface class SettingsRepository {
  /// The settings, with defaults while the document does not exist.
  Stream<UserSettings> watch(String uid);
  Future<void> saveNotifications(String uid, NotificationSettings settings);
  Future<void> savePrivacy(String uid, PrivacySettings privacy);

  /// The app's language, so pushes arrive in it.
  Future<void> saveLanguage(String uid, String languageCode);
  Future<void> setChatMuted(String uid, String chatId, {required bool muted});
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

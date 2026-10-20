import 'dart:typed_data';

import '../models/app_notification.dart';
import '../models/capsule.dart';
import '../models/chat.dart';
import '../models/friend_request.dart';
import '../models/social.dart';
import '../models/user_profile.dart';
import '../models/world.dart';
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

  /// The account can also sign in with Google.
  bool get hasGoogle;

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

  /// The "about me" line (empty removes it).
  Future<void> setAbout(String uid, String about);

  /// What others find [uid] by when searching names; null takes them out of
  /// the name search.
  Future<void> setSearchName(String uid, String? lowerCaseName);

  /// Prefix search on lower-case names of people who allow it.
  Future<List<UserProfile>> searchByName(String prefix, {int limit});
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
  /// already arrived does nothing. [replyTo] quotes the message it answers.
  Future<void> sendText({
    required String from,
    required String to,
    required String text,
    required String messageId,
    MessageReply? replyTo,
    bool forwarded = false,
    MessageCapsuleRef? capsuleRef,
  });

  /// Uploads the photo at [localPath] (resized, JPEG) for message
  /// [messageId] from [from] to [to]; returns where it is stored.
  Future<ChatPhoto> uploadPhoto({
    required String from,
    required String to,
    required String messageId,
    required String localPath,
  });

  /// Sends [photo] (from [uploadPhoto]) as message [messageId], with
  /// [caption] under it. Like [sendText] otherwise.
  Future<void> sendPhoto({
    required String from,
    required String to,
    required String messageId,
    required ChatPhoto photo,
    String caption = '',
    MessageReply? replyTo,
  });

  /// [uid] is typing in [chatId] now ([typing]), or stopped.
  Future<void> setTyping(String chatId, String uid, {required bool typing});

  /// Who says they are typing in [chatId], and since when (server time).
  Stream<Map<String, DateTime>> watchTyping(String chatId);

  /// Groups [uid] is in, most recently active first.
  Stream<List<Chat>> watchGroups(String uid);

  /// A new group named [name] with [creator] in it; [invitees] are invited
  /// (the server adds the ones it accepts). Returns its id.
  Future<String> createGroup({
    required String creator,
    required String name,
    required List<String> invitees,
  });

  /// [by] invites [invitees] to [groupId].
  Future<void> inviteToGroup(
    String groupId, {
    required String by,
    required List<String> invitees,
  });

  Future<void> renameGroup(String groupId, String name);

  /// [uid] leaves [groupId] (their read mark goes with them).
  Future<void> leaveGroup(String groupId, String uid);

  /// [uid] has read [groupId] up to now.
  Future<void> markGroupRead(String groupId, String uid);

  /// Sends [text] to [groupId] as message [messageId] (one batched write, so
  /// it also waits offline).
  Future<void> sendToGroup({
    required String groupId,
    required String from,
    required String text,
    required String messageId,
    MessageReply? replyTo,
    bool forwarded = false,
  });

  /// Uploads the recording at [localPath] (AAC, .m4a) for message
  /// [messageId] from [from] to [to].
  Future<ChatAudio> uploadVoice({
    required String from,
    required String to,
    required String messageId,
    required String localPath,
  });

  /// Sends [audio] (from [uploadVoice]) as voice message [messageId].
  Future<void> sendVoice({
    required String from,
    required String to,
    required String messageId,
    required ChatAudio audio,
    required int durationMs,
    required List<int> waveform,
    MessageReply? replyTo,
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

  /// [uid]'s reaction to message [messageId] of [chatId]; null removes it.
  Future<void> setMessageReaction(
    String chatId,
    String messageId, {
    required String uid,
    ReactionType? type,
  });

  /// Deletes one message of [chatId] for both participants. When it was the
  /// newest, the chat list shows the one before it again (or nothing). A
  /// photo's file ([imagePath]) goes too. [unreadFor]: the participant who
  /// had not read it yet gets one fewer unread.
  Future<void> deleteMessage(
    String chatId,
    String messageId, {
    String? imagePath,
    String? unreadFor,
  });
}

abstract interface class CapsuleRepository {
  Stream<List<Capsule>> watchOwn(String uid);

  /// One capsule, or null when it does not exist or is not visible.
  Future<Capsule?> getById(String id);

  /// One capsule, live (counters move as people react and comment); null
  /// when it is deleted or not visible.
  Stream<Capsule?> watchById(String id);

  /// What a friend shares with the user: [ownerId]'s public and friends-only
  /// capsules, newest first, at most [limit] of each.
  Future<List<Capsule>> sharedBy(String ownerId, {int limit});

  /// Capsules [uid] co-authored (someone else's), newest first.
  Stream<List<Capsule>> watchCoAuthored(String uid);

  /// [uid] takes themselves off capsule [capsuleId] as a co-author.
  Future<void> leaveCoAuthors(String capsuleId, String uid);

  /// Friends-only capsules of [friendIds] (chunked `whereIn`).
  Stream<List<Capsule>> watchFriends(List<String> friendIds);

  /// Public capsules whose latitude is within [minLat]..[maxLat].
  Stream<List<Capsule>> watchPublicInBand(
    double minLat,
    double maxLat, {
    int limit,
  });

  // The map's sync (docs/map/COLD_START.md): what changed since the pins the
  // phone keeps. Capsules are never edited, so a change is a new capsule
  // (its server-set createdAt) or a deleted one.

  /// Friends-only capsules of [friendIds] created after [after], newest
  /// first, at most [limit] per chunk of friends.
  Stream<List<Capsule>> watchFriendsSince(
    List<String> friendIds,
    DateTime after, {
    int limit,
  });

  /// Public capsules created after [after], anywhere, newest first, at most
  /// [limit].
  Stream<List<Capsule>> watchPublicSince(DateTime after, {int limit});

  /// Friends-only capsules of [friendIds] and public capsules deleted after
  /// [after] (functions/lib/mapsync.js), at most [limit] of each query.
  Stream<List<CapsuleDeletion>> watchDeletionsSince(
    List<String> friendIds,
    DateTime after, {
    int limit,
  });

  /// [getById] from this phone's copy only (no wait for the network; null
  /// when it has none): what to show at once, while [getById] checks.
  Future<Capsule?> getCachedById(String id);

  /// An id for a new capsule, made on the device (see [CapsuleDraft.id]).
  String newCapsuleId();

  /// Uploads the photo and writes the capsule. With [CapsuleDraft.id] it is
  /// idempotent: a capsule that already exists under that id is returned
  /// as is (an earlier attempt succeeded but its answer was lost).
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

  /// [uid] opened someone else's [capsuleId] (B7): a marker a function
  /// counts once ("Curious"). Never throws.
  Future<void> markViewed(String uid, String capsuleId);

  /// Countries and towns of [uid]'s capsules (B7; own, or a friend's when
  /// they share their achievements). Empty when there is none yet.
  Stream<WorldSummary> watchWorld(String uid);

  /// Messages from the Later team, newest first.
  Stream<List<Announcement>> watchAnnouncements({int limit});
}

/// App-wide configuration (read-only for the app).
abstract interface class ConfigRepository {
  /// The `entitlements/limits` document (B7), or null when there is none.
  Future<Map<String, Object?>?> limits();
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

  Future<void> setChatPinned(String uid, String chatId, {required bool pinned});

  /// The friends first on the profile (the whole list, in order).
  Future<void> setPinnedFriends(String uid, List<String> friends);
}

/// The server's answer to a look-up in the phone's contacts.
class ContactMatches {
  const ContactMatches({required this.done, this.matches = const []});

  /// Answered (the hashes are gone by then).
  final bool done;

  /// People found who allow it, not blocked either way.
  final List<String> matches;
}

/// Friend suggestions from contacts (contactMatches/{uid}, B3).
abstract interface class ContactMatchRepository {
  /// Sends the hashes; a [PermissionFailure] within the hour of the last.
  Future<void> requestMatches(String uid, List<String> hashes);

  /// The latest request's state; null while nothing was asked or it is
  /// still on its way.
  Stream<ContactMatches?> watchMatches(String uid);
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

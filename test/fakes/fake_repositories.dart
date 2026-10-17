import 'dart:async';
import 'dart:typed_data';

import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/models/app_notification.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/chat.dart';
import 'package:later/data/models/friend_request.dart';
import 'package:later/data/models/social.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/models/user_settings.dart';
import 'package:later/data/repositories/repositories.dart';

/// In-memory auth for controller tests.
class FakeAuthRepository implements AuthRepository {
  final _uid = StreamController<String?>.broadcast();
  String? _current;
  final Map<String, String> accounts = {}; // email -> password
  final Map<String, String> uidsByEmail = {};
  SocialSignInResult? googleResult;
  int deletedUsers = 0;
  int signOuts = 0;
  final List<String> calls = [];

  void emit(String? uid) {
    _current = uid;
    _uid.add(uid);
  }

  @override
  Stream<String?> uidChanges() => seeded(() => _current, _uid.stream);

  @override
  String? get currentUid => _current;

  @override
  String? get currentEmail => _current == null
      ? null
      : uidsByEmail.entries.firstWhere((e) => e.value == _current).key;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    calls.add('signIn:$email');
    if (accounts[email] != password) {
      throw const AuthFailure('Wrong email or password.');
    }
    emit(uidsByEmail[email]);
  }

  @override
  Future<String> createAccount(String email, String password) async {
    calls.add('create:$email');
    if (accounts.containsKey(email)) {
      throw const AuthFailure('The account already exists for that email.');
    }
    accounts[email] = password;
    final uid = 'uid-${accounts.length}';
    uidsByEmail[email] = uid;
    emit(uid);
    return uid;
  }

  @override
  Future<SocialSignInResult?> signInWithGoogle() async {
    if (googleResult != null) emit(googleResult!.uid);
    return googleResult;
  }

  @override
  Future<void> sendPasswordReset(String email) async =>
      calls.add('reset:$email');

  @override
  Future<void> updateDisplayName(String name) async {}

  @override
  Future<void> deleteCurrentUser() async {
    deletedUsers++;
    emit(null);
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    emit(null);
  }

  @override
  bool hasPassword = true;

  /// What the Google picker does on re-authentication: null = cancelled.
  bool? googleReauth = true;

  @override
  Future<bool> reauthenticate({String? password}) async {
    calls.add('reauth');
    if (password == null) return googleReauth ?? false;
    final email = currentEmail;
    if (email == null || accounts[email] != password) {
      throw const AuthFailure('Wrong password.');
    }
    return true;
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    calls.add('password');
    accounts[currentEmail!] = newPassword;
  }

  @override
  Future<void> requestEmailChange(String newEmail) async =>
      calls.add('email:$newEmail');

  @override
  Future<void> deleteAccount() async {
    calls.add('delete');
    final email = currentEmail;
    if (email != null) {
      accounts.remove(email);
      uidsByEmail.remove(email);
    }
    emit(null);
  }
}

/// In-memory settings documents.
class FakeSettingsRepository implements SettingsRepository {
  final Map<String, UserSettings> docs = {};
  final _changes = StreamController<String>.broadcast();
  bool failWrites = false;

  @override
  Stream<UserSettings> watch(String uid) => seeded(
    () => docs[uid] ?? const UserSettings(),
    _changes.stream
        .where((u) => u == uid)
        .map((_) => docs[uid] ?? const UserSettings()),
  );

  void _check() {
    if (failWrites) {
      throw const PermissionFailure('denied');
    }
  }

  @override
  Future<void> saveNotifications(
    String uid,
    NotificationSettings settings,
  ) async {
    _check();
    docs[uid] = (docs[uid] ?? const UserSettings()).copyWith(
      notifications: settings,
    );
    _changes.add(uid);
  }

  @override
  Future<void> savePrivacy(String uid, PrivacySettings privacy) async {
    _check();
    docs[uid] = (docs[uid] ?? const UserSettings()).copyWith(privacy: privacy);
    _changes.add(uid);
  }

  @override
  Future<void> saveLanguage(String uid, String languageCode) async {
    _check();
    docs[uid] = (docs[uid] ?? const UserSettings()).copyWith(
      language: languageCode,
    );
    _changes.add(uid);
  }

  @override
  Future<void> setChatMuted(
    String uid,
    String chatId, {
    required bool muted,
  }) async {
    _check();
    final current = docs[uid] ?? const UserSettings();
    docs[uid] = current.copyWith(
      mutedChats: muted
          ? {...current.mutedChats, chatId}
          : ({...current.mutedChats}..remove(chatId)),
    );
    _changes.add(uid);
  }
}

class FakeUserRepository implements UserRepository {
  final Map<String, UserProfile> profiles = {};
  final Set<String> takenUsernames = {};
  final _changes = StreamController<String>.broadcast();

  @override
  Stream<UserProfile?> watchProfile(String uid) =>
      seeded(() => profiles[uid], _changes.stream.where((id) => id == uid));

  void put(UserProfile p) {
    profiles[p.uid] = p;
    _changes.add(p.uid);
  }

  @override
  Future<UserProfile?> getProfile(String uid) async => profiles[uid];

  int getProfilesCalls = 0;

  @override
  Future<Map<String, UserProfile>> getProfiles(Iterable<String> uids) async {
    getProfilesCalls++;
    return {
      for (final id in uids)
        if (profiles[id] != null) id: profiles[id]!,
    };
  }

  @override
  Future<bool> isUsernameTaken(String username) async =>
      takenUsernames.contains(username);

  @override
  Future<void> createProfile({
    required String uid,
    required String name,
    required String username,
  }) async {
    if (takenUsernames.contains(username)) {
      throw const ValidationFailure('Username already taken');
    }
    takenUsernames.add(username);
    put(UserProfile(uid: uid, name: name, username: username));
  }

  @override
  Future<void> updateName(String uid, String name) async {
    final p = profiles[uid]!;
    put(UserProfile(uid: uid, name: name, username: p.username));
  }

  @override
  Future<void> changeUsername(String uid, String newUsername) async {
    if (takenUsernames.contains(newUsername)) {
      throw const ValidationFailure('Username already taken');
    }
    final p = profiles[uid]!;
    takenUsernames
      ..remove(p.username)
      ..add(newUsername);
    put(UserProfile(uid: uid, name: p.name, username: newUsername));
  }

  @override
  Future<List<UserProfile>> searchByUsername(
    String prefix, {
    int limit = 20,
  }) async => profiles.values
      .where((p) => p.username.startsWith(prefix))
      .take(limit)
      .toList();

  @override
  Future<void> setShowAchievements(String uid, bool show) async =>
      put(profiles[uid]!.copyWith(showAchievements: show));

  @override
  Future<void> setFavorite(String uid, String capsuleId, bool favorite) async {
    final p = profiles[uid]!;
    final favorites = {...p.favorites};
    favorite ? favorites.add(capsuleId) : favorites.remove(capsuleId);
    put(
      UserProfile(
        uid: uid,
        name: p.name,
        username: p.username,
        friends: p.friends,
        favorites: favorites,
      ),
    );
  }
}

class FakeNotificationRepository implements NotificationRepository {
  final Map<String, List<AppNotification>> byUser = {};
  final _changes = StreamController<String>.broadcast();
  final List<String> calls = [];

  void put(String uid, List<AppNotification> list) {
    byUser[uid] = list;
    _changes.add(uid);
  }

  @override
  Stream<List<AppNotification>> watch(String uid, {int limit = 100}) => seeded(
    () => byUser[uid] ?? const <AppNotification>[],
    _changes.stream.where((id) => id == uid),
  );

  @override
  Future<void> markRead(String uid, Iterable<String> ids) async {
    calls.add('markRead:${ids.join(',')}');
    put(uid, [
      for (final n in byUser[uid] ?? <AppNotification>[])
        ids.contains(n.id) ? n.markedRead() : n,
    ]);
  }

  @override
  Future<void> delete(String uid, Iterable<String> ids) async {
    calls.add('delete:${ids.join(',')}');
    put(uid, [
      for (final n in byUser[uid] ?? <AppNotification>[])
        if (!ids.contains(n.id)) n,
    ]);
  }

  @override
  Future<void> createFollowNotification({
    required String targetUid,
    required String fromUid,
    required String fromUserName,
  }) async => calls.add('follow:$fromUid->$targetUid');
}

class FakePushTokenRepository implements PushTokenRepository {
  final Map<String, Set<String>> tokens = {};

  @override
  Future<void> saveToken(String uid, String token, String platform) async =>
      (tokens[uid] ??= {}).add(token);

  @override
  Future<void> deleteToken(String uid, String token) async =>
      tokens[uid]?.remove(token);
}

class FakeFriendsRepository implements FriendsRepository {
  final _requests = <String, FriendRequest>{};
  final _changes = StreamController<void>.broadcast();
  final List<String> calls = [];

  void _notify() => _changes.add(null);

  Stream<List<FriendRequest>> _watch(bool Function(FriendRequest) where) =>
      seeded(() => _requests.values.where(where).toList(), _changes.stream);

  @override
  Stream<List<FriendRequest>> watchOutgoingPending(String uid) => _watch(
    (r) => r.fromUserId == uid && r.status == FriendRequestStatus.pending,
  );

  @override
  Stream<List<FriendRequest>> watchIncomingPending(String uid) => _watch(
    (r) => r.toUserId == uid && r.status == FriendRequestStatus.pending,
  );

  @override
  Future<void> sendRequest({required String from, required String to}) async {
    calls.add('send:$from->$to');
    _requests[FriendRequest.idFor(from, to)] = FriendRequest(
      fromUserId: from,
      toUserId: to,
      status: FriendRequestStatus.pending,
    );
    _notify();
  }

  @override
  Future<void> cancelRequest({required String from, required String to}) async {
    calls.add('cancel:$from->$to');
    _requests.remove(FriendRequest.idFor(from, to));
    _notify();
  }

  @override
  Future<void> acceptRequest({required String from, required String to}) async {
    calls.add('accept:$from->$to');
    _requests[FriendRequest.idFor(from, to)] = FriendRequest(
      fromUserId: from,
      toUserId: to,
      status: FriendRequestStatus.accepted,
    );
    _notify();
  }

  @override
  Future<void> rejectRequest({required String from, required String to}) async {
    calls.add('reject:$from->$to');
    _requests.remove(FriendRequest.idFor(from, to));
    _notify();
  }

  @override
  Future<void> removeFriend({
    required String me,
    required String friend,
  }) async => calls.add('remove:$me-$friend');

  final Set<String> following = {};

  @override
  Future<bool> isFollowing({
    required String me,
    required String target,
  }) async => following.contains('$me>$target');

  @override
  Future<void> follow({
    required String me,
    required String target,
    required String myUsername,
  }) async => following.add('$me>$target');

  @override
  Future<void> unfollow({required String me, required String target}) async =>
      following.remove('$me>$target');

  /// "uid>other" pairs: uid blocked other.
  final Set<String> blocks = {};

  @override
  Stream<Set<String>> watchBlocked(String uid) => seeded(
    () => {
      for (final b in blocks)
        if (b.startsWith('$uid>')) b.substring(uid.length + 1),
    },
    _changes.stream,
  );

  @override
  Future<void> block({required String me, required String other}) async {
    blocks.add('$me>$other');
    _notify();
  }

  @override
  Future<void> unblock({required String me, required String other}) async {
    blocks.remove('$me>$other');
    _notify();
  }

  @override
  Future<bool> isBlockedBy({required String me, required String other}) async =>
      blocks.contains('$other>$me');
}

/// In-memory chats. [failSends] makes every send throw.
class FakeChatRepository implements ChatRepository {
  final _changes = StreamController<void>.broadcast();
  final Map<String, List<ChatMessage>> messages = {};
  final Map<String, Chat> chats = {};
  final List<String> calls = [];
  bool failSends = false;

  /// Clock used for message times and read receipts.
  DateTime now = DateTime(2026, 10, 16, 12);
  int _ids = 0;

  void _notify() => _changes.add(null);

  @override
  Stream<List<Chat>> watchChats(String uid) => seeded(
    () => chats.values
        .where((c) => c.participants.contains(uid) && c.hasMessages)
        .toList(),
    _changes.stream,
  );

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId, {int limit = 50}) =>
      seeded(() {
        final all = messages[chatId] ?? const <ChatMessage>[];
        return List.of(all.skip(all.length > limit ? all.length - limit : 0));
      }, _changes.stream);

  @override
  String newMessageId(String chatId) => 'm${_ids++}';

  void _add(String from, String to, ChatMessage message) {
    if (failSends) throw StateError('send failed');
    final chatId = Chat.idBetween(from, to);
    final list = messages[chatId] ??= [];
    if (list.any((m) => m.id == message.id)) return; // already arrived
    list.add(message);
    final old = chats[chatId];
    chats[chatId] = Chat(
      id: chatId,
      participants: [from, to],
      lastMessage: message.text,
      lastUpdated: now,
      lastSenderId: from,
      unreadCounts: {...?old?.unreadCounts, to: (old?.unreadFor(to) ?? 0) + 1},
      lastReadAt: old?.lastReadAt ?? const {},
    );
    _notify();
  }

  @override
  Future<void> sendText({
    required String from,
    required String to,
    required String text,
    required String messageId,
  }) async {
    calls.add('text:$from->$to:$text');
    _add(
      from,
      to,
      ChatMessage(id: messageId, senderId: from, text: text, sentAt: now),
    );
  }

  @override
  Future<void> sendCapsule({
    required String from,
    required String to,
    required Capsule capsule,
  }) async {
    calls.add('capsule:$from->$to:${capsule.id}');
    _add(
      from,
      to,
      ChatMessage(
        id: 'capsule_${capsule.id}',
        senderId: from,
        text: capsule.title,
        sentAt: now,
        type: ChatMessageType.capsule,
        capsuleId: capsule.id,
        imageUrl: capsule.imageUrl,
      ),
    );
  }

  @override
  Future<void> markRead(String chatId, {required String reader}) async {
    calls.add('read:$chatId:$reader');
    final chat = chats[chatId];
    if (chat == null) return;
    chats[chatId] = Chat(
      id: chat.id,
      participants: chat.participants,
      lastMessage: chat.lastMessage,
      lastUpdated: chat.lastUpdated,
      lastSenderId: chat.lastSenderId,
      unreadCounts: {...chat.unreadCounts, reader: 0},
      lastReadAt: {...chat.lastReadAt, reader: now},
    );
    _notify();
  }

  @override
  Future<void> clearHistory(String chatId) async {
    calls.add('clear:$chatId');
    messages.remove(chatId);
    final chat = chats[chatId];
    if (chat != null) {
      chats[chatId] = Chat(id: chat.id, participants: chat.participants);
    }
    _notify();
  }
}

class FakeCapsuleRepository implements CapsuleRepository {
  final _own = StreamController<List<Capsule>>.broadcast();
  List<Capsule> own = [];
  final List<CapsuleDraft> created = [];
  final List<String> deleted = [];

  void emitOwn(List<Capsule> list) {
    own = list;
    _own.add(list);
  }

  @override
  Stream<List<Capsule>> watchOwn(String uid) => seeded(() => own, _own.stream);

  Capsule? byId;

  @override
  Future<Capsule?> getById(String id) async => byId?.id == id ? byId : null;

  final _byIdChanges = StreamController<void>.broadcast();

  /// Replaces [byId] and tells [watchById] listeners.
  void emitById(Capsule? capsule) {
    byId = capsule;
    _byIdChanges.add(null);
  }

  @override
  Stream<Capsule?> watchById(String id) =>
      seeded(() => byId?.id == id ? byId : null, _byIdChanges.stream);

  @override
  Stream<List<Capsule>> watchFriends(List<String> friendIds) =>
      Stream.value(const []);

  @override
  Stream<List<Capsule>> watchPublicInBand(
    double minLat,
    double maxLat, {
    int limit = 300,
  }) => Stream.value(const []);

  @override
  Future<Capsule> create(CapsuleDraft draft) async {
    created.add(draft);
    return Capsule(
      id: 'new-${created.length}',
      ownerId: draft.ownerId,
      title: draft.title,
      privacy: draft.privacy,
      color: draft.color,
    );
  }

  @override
  Future<void> delete(Iterable<Capsule> capsules) async =>
      deleted.addAll(capsules.map((c) => c.id));
}

/// In-memory reactions, comments, reports, achievements and announcements.
class FakeSocialRepository implements SocialRepository {
  final Map<String, Map<String, ReactionType>> reactions = {};
  final Map<String, List<CapsuleComment>> comments = {};
  final Map<String, List<UnlockedAchievement>> achievements = {};
  List<Announcement> announcements = [];
  final List<Map<String, Object?>> reports = [];
  final _changes = StreamController<void>.broadcast();
  bool failWrites = false;
  var _ids = 0;

  void changed() => _changes.add(null);

  void _check() {
    if (failWrites) throw const PermissionFailure('denied');
  }

  @override
  Stream<List<CapsuleReaction>> watchReactions(
    String capsuleId, {
    int limit = 100,
  }) => seeded(
    () => [
      for (final e in (reactions[capsuleId] ?? const {}).entries)
        CapsuleReaction(uid: e.key, type: e.value),
    ].take(limit).toList(),
    _changes.stream,
  );

  @override
  Stream<ReactionType?> watchMyReaction(String capsuleId, String uid) =>
      seeded(() => reactions[capsuleId]?[uid], _changes.stream);

  @override
  Future<void> setReaction(
    String capsuleId,
    String uid,
    ReactionType? type,
  ) async {
    _check();
    final map = reactions.putIfAbsent(capsuleId, () => {});
    type == null ? map.remove(uid) : map[uid] = type;
    changed();
  }

  @override
  Stream<List<CapsuleComment>> watchComments(
    String capsuleId, {
    int limit = 200,
  }) => seeded(() {
    final all = comments[capsuleId] ?? const <CapsuleComment>[];
    return all.length <= limit ? [...all] : all.sublist(all.length - limit);
  }, _changes.stream);

  @override
  Future<void> addComment(
    String capsuleId, {
    required String authorId,
    required String text,
    String? replyTo,
  }) async {
    _check();
    comments
        .putIfAbsent(capsuleId, () => [])
        .add(
          CapsuleComment(
            id: 'c${++_ids}',
            capsuleId: capsuleId,
            authorId: authorId,
            text: text,
            createdAt: DateTime(2026, 1, 1).add(Duration(minutes: _ids)),
            replyTo: replyTo,
          ),
        );
    changed();
  }

  @override
  Future<void> deleteComment(String capsuleId, String commentId) async {
    _check();
    comments[capsuleId]?.removeWhere((c) => c.id == commentId);
    changed();
  }

  @override
  Future<void> report({
    required String reporterId,
    required ReportTarget target,
    required String targetPath,
    required ReportReason reason,
    String? details,
  }) async {
    _check();
    reports.add({
      'reporterId': reporterId,
      'target': target,
      'targetPath': targetPath,
      'reason': reason,
      'details': details,
    });
  }

  @override
  Stream<List<UnlockedAchievement>> watchAchievements(String uid) =>
      seeded(() => [...?achievements[uid]], _changes.stream);

  @override
  Stream<List<Announcement>> watchAnnouncements({int limit = 20}) =>
      seeded(() => announcements.take(limit).toList(), _changes.stream);
}

class FakeImageStorageRepository implements ImageStorageRepository {
  final Map<String, String> urls = {};
  final List<String> calls = [];

  @override
  Future<String?> imageUrl(
    String uid,
    ProfileImageKind kind, {
    bool small = false,
  }) async => urls['$uid/${kind.name}'];

  @override
  Future<void> uploadProfileImage(String uid, Uint8List bytes) async {
    calls.add('upload-profile:$uid');
    urls['$uid/profile'] = 'https://img/$uid/profile';
  }

  @override
  Future<void> uploadBackgroundImage(String uid, Uint8List bytes) async {
    calls.add('upload-background:$uid');
    urls['$uid/background'] = 'https://img/$uid/background';
  }

  @override
  Future<void> deleteImage(String uid, ProfileImageKind kind) async {
    calls.add('delete-${kind.name}:$uid');
    urls.remove('$uid/${kind.name}');
  }
}

/// A stream that emits the current value on listen, then once per change.
/// Subscribes synchronously, so no change can be missed between the two.
Stream<T> seeded<T>(T Function() current, Stream<Object?> changes) =>
    Stream<T>.multi((controller) {
      controller.add(current());
      final sub = changes.listen((_) => controller.add(current()));
      controller.onCancel = sub.cancel;
    });

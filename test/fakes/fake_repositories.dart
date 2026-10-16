import 'dart:async';
import 'dart:typed_data';

import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/models/app_notification.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/friend_request.dart';
import 'package:later/data/models/user_profile.dart';
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

  @override
  Future<Map<String, UserProfile>> getProfiles(Iterable<String> uids) async => {
    for (final id in uids)
      if (profiles[id] != null) id: profiles[id]!,
  };

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

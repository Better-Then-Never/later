import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/firebase/firebase_capsule_repository.dart';
import 'package:later/data/firebase/firebase_chat_repository.dart';
import 'package:later/data/firebase/firebase_friends_repository.dart';
import 'package:later/data/firebase/firebase_notification_repository.dart';
import 'package:later/data/firebase/firebase_push_token_repository.dart';
import 'package:later/data/firebase/firebase_user_repository.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/chat.dart';

void main() {
  late FakeFirebaseFirestore db;

  setUp(() => db = FakeFirebaseFirestore());

  group('FirebaseUserRepository', () {
    late FirebaseUserRepository repo;
    setUp(() => repo = FirebaseUserRepository(firestore: db));

    test('createProfile writes profile and reserves username', () async {
      await repo.createProfile(uid: 'u1', name: 'Alice', username: 'alice');
      final user = await db.doc('users/u1').get();
      expect(user['username'], 'alice');
      expect(user['friends'], isEmpty);
      expect(user.data()!.containsKey('email'), isFalse);
      expect((await db.doc('usernames/alice').get())['uid'], 'u1');
    });

    test(
      'createProfile rejects a taken (reserved or legacy) username',
      () async {
        await db.doc('usernames/bob').set({'uid': 'other'});
        await db.doc('users/legacy').set({'username': 'carol'});
        expect(
          () => repo.createProfile(uid: 'u1', name: 'B', username: 'bob'),
          throwsA(isA<ValidationFailure>()),
        );
        expect(
          () => repo.createProfile(uid: 'u1', name: 'C', username: 'carol'),
          throwsA(isA<ValidationFailure>()),
        );
      },
    );

    test('changeUsername moves the reservation', () async {
      await repo.createProfile(uid: 'u1', name: 'Alice', username: 'alice');
      await repo.changeUsername('u1', 'alicia');
      expect((await db.doc('users/u1').get())['username'], 'alicia');
      expect((await db.doc('usernames/alicia').get())['uid'], 'u1');
      expect((await db.doc('usernames/alice').get()).exists, isFalse);
    });

    test('changeUsername rejects a username owned by someone else', () async {
      await repo.createProfile(uid: 'u1', name: 'A', username: 'alice');
      await repo.createProfile(uid: 'u2', name: 'B', username: 'bobby');
      expect(
        () => repo.changeUsername('u1', 'bobby'),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('getProfiles batches more than 30 ids', () async {
      for (var i = 0; i < 35; i++) {
        await db.doc('users/u$i').set({'name': 'n$i', 'username': 'user$i'});
      }
      final profiles = await repo.getProfiles([
        for (var i = 0; i < 35; i++) 'u$i',
        'missing',
      ]);
      expect(profiles.length, 35);
      expect(profiles['u34']!.name, 'n34');
    });

    test('searchByUsername is a bounded prefix search', () async {
      for (final u in ['dave', 'davem', 'daisy', 'bob']) {
        await db.doc('users/$u').set({'name': u, 'username': u});
      }
      final da = await repo.searchByUsername('dav');
      expect(da.map((p) => p.username), ['dave', 'davem']);
      final limited = await repo.searchByUsername('', limit: 2);
      expect(limited.length, 2);
    });

    test('setFavorite adds and removes ids', () async {
      await repo.setFavorite('u1', 'c1', true);
      await repo.setFavorite('u1', 'c2', true);
      await repo.setFavorite('u1', 'c1', false);
      expect((await db.doc('users/u1').get())['favorites'], ['c2']);
    });
  });

  group('FirebaseFriendsRepository', () {
    late FirebaseFriendsRepository repo;
    setUp(() => repo = FirebaseFriendsRepository(firestore: db));

    test('request lifecycle: send, list, accept, remove', () async {
      await db.doc('users/a').set({'friends': <String>[]});
      await db.doc('users/b').set({'friends': <String>[]});
      await repo.sendRequest(from: 'a', to: 'b');
      expect(
        (await repo.watchIncomingPending('b').first).single.fromUserId,
        'a',
      );
      expect((await repo.watchOutgoingPending('a').first).single.toUserId, 'b');

      await repo.acceptRequest(from: 'a', to: 'b');
      expect((await db.doc('friend_requests/a_b').get())['status'], 'accepted');
      expect((await db.doc('users/a').get())['friends'], ['b']);
      expect((await db.doc('users/b').get())['friends'], ['a']);
      expect(await repo.watchIncomingPending('b').first, isEmpty);

      await repo.removeFriend(me: 'b', friend: 'a');
      expect((await db.doc('users/a').get())['friends'], isEmpty);
      expect((await db.doc('users/b').get())['friends'], isEmpty);
      expect((await db.doc('friend_requests/a_b').get()).exists, isFalse);
    });

    test('follow and unfollow write both sides', () async {
      await repo.follow(me: 'a', target: 'b', myUsername: 'alice');
      expect(await repo.isFollowing(me: 'a', target: 'b'), isTrue);
      expect((await db.doc('users/b/followers/a').get()).exists, isTrue);
      await repo.unfollow(me: 'a', target: 'b');
      expect(await repo.isFollowing(me: 'a', target: 'b'), isFalse);
    });
  });

  group('FirebaseNotificationRepository', () {
    late FirebaseNotificationRepository repo;
    setUp(() => repo = FirebaseNotificationRepository(firestore: db));

    test('watch is ordered newest first; markRead and delete by id', () async {
      final col = db.collection('users/u1/notifications');
      await col.doc('old').set({
        'type': 'follow',
        'timestamp': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'isRead': false,
      });
      await col.doc('new').set({
        'type': 'capsule',
        'timestamp': Timestamp.fromDate(DateTime(2026, 2, 1)),
        'isRead': false,
      });
      expect((await repo.watch('u1').first).map((n) => n.id), ['new', 'old']);
      await repo.markRead('u1', ['old']);
      expect((await col.doc('old').get())['isRead'], isTrue);
      expect((await col.doc('new').get())['isRead'], isFalse);
      await repo.delete('u1', ['new']);
      expect((await repo.watch('u1').first).map((n) => n.id), ['old']);
    });

    test('follow notification shape', () async {
      await repo.createFollowNotification(
        targetUid: 'b',
        fromUid: 'a',
        fromUserName: 'alice',
      );
      final n = (await repo.watch('b').first).single;
      expect(n.fromUserId, 'a');
      expect(n.message, 'started following you');
      expect(n.isRead, isFalse);
    });
  });

  test(
    'push tokens: save per device, delete also clears legacy field',
    () async {
      final repo = FirebasePushTokenRepository(firestore: db);
      await db.doc('users/u1').set({'fcmToken': 'tok', 'name': 'x'});
      await repo.saveToken('u1', 'tok', 'android');
      expect(
        (await db.doc('users/u1/fcmTokens/tok').get())['platform'],
        'android',
      );
      await repo.deleteToken('u1', 'tok');
      expect((await db.doc('users/u1/fcmTokens/tok').get()).exists, isFalse);
      expect(
        (await db.doc('users/u1').get()).data()!.containsKey('fcmToken'),
        isFalse,
      );
    },
  );

  group('FirebaseCapsuleRepository queries', () {
    late FirebaseCapsuleRepository repo;
    setUp(() => repo = FirebaseCapsuleRepository(firestore: db));

    Future<void> add(String id, Map<String, dynamic> data) =>
        db.doc('capsules/$id').set({
          'title': id,
          'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
          ...data,
        });

    test('watchOwn returns only own capsules, newest first', () async {
      await add('a1', {
        'ownerId': 'a',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      });
      await add('a2', {
        'ownerId': 'a',
        'createdAt': Timestamp.fromDate(DateTime(2026, 3, 1)),
      });
      await add('b1', {'ownerId': 'b'});
      final own = await repo.watchOwn('a').first;
      expect(own.map((c) => c.id), ['a2', 'a1']);
    });

    test('watchFriends returns friends-only capsules of friends', () async {
      await add('f1', {'ownerId': 'f', 'privacy': 'friends'});
      await add('f2', {'ownerId': 'f', 'privacy': 'private'});
      await add('f3', {'ownerId': 'f', 'privacy': 'public'});
      await add('x1', {'ownerId': 'x', 'privacy': 'friends'});
      final list = await repo.watchFriends(['f']).first;
      expect(list.map((c) => c.id), ['f1']);
      expect(await repo.watchFriends([]).first, isEmpty);
    });

    test('watchFriends merges more than 30 friends', () async {
      final ids = [for (var i = 0; i < 40; i++) 'f$i'];
      for (final id in ids) {
        await add('c_$id', {'ownerId': id, 'privacy': 'friends'});
      }
      expect((await repo.watchFriends(ids).first).length, 40);
    });

    test(
      'watchPublicInBand filters by privacy and latitude',
      () async {
        await add('in', {
          'ownerId': 'x',
          'privacy': 'public',
          'location': const GeoPoint(37.5, -122),
        });
        await add('north', {
          'ownerId': 'x',
          'privacy': 'public',
          'location': const GeoPoint(40, -122),
        });
        await add('private', {
          'ownerId': 'x',
          'privacy': 'private',
          'location': const GeoPoint(37.5, -122),
        });
        final list = await repo.watchPublicInBand(37, 38).first;
        expect(list.map((c) => c.id), ['in']);
        expect(list.single.privacy, CapsulePrivacy.public);
      },
      skip:
          'fake_cloud_firestore cannot order GeoPoints; covered against the real emulator in tools/rules-tests',
    );
  });

  group('FirebaseChatRepository', () {
    test(
      'the first message creates the chat; later ones add one unread each',
      () async {
        final repo = FirebaseChatRepository(firestore: db);
        await repo.sendText(from: 'a', to: 'b', text: 'hi', messageId: 'm1');
        var chat = (await db.doc('chats/a_b').get()).data()!;
        expect(chat['participants'], ['a', 'b']);
        expect(chat['unreadCounts'], {'b': 1});

        // The chat is known here now: the queued (batched) path.
        await repo.sendText(from: 'a', to: 'b', text: 'again', messageId: 'm2');
        await repo.sendText(from: 'b', to: 'a', text: 'yes', messageId: 'm3');
        chat = (await db.doc('chats/a_b').get()).data()!;
        expect(chat['unreadCounts'], {'b': 2, 'a': 1});
        expect(chat['lastMessage'], 'yes');
        expect(chat['lastSenderId'], 'b');

        final messages = await repo.watchMessages('a_b').first;
        expect(messages.map((m) => m.text), ['hi', 'again', 'yes']);
        expect(messages.map((m) => m.delivery).toSet(), {MessageDelivery.sent});
      },
    );
  });
}

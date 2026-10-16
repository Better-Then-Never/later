import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/models/friend_request.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/friends/friend_suggestions_controller.dart';
import 'package:later/features/friends/friends_store.dart';
import 'package:later/features/friends/pages/my_friends_page.dart';
import 'package:later/features/friends/pinned_friends_controller.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_repositories.dart';

UserProfile _p(String uid, {String? name, List<String> friends = const []}) =>
    UserProfile(uid: uid, name: name ?? uid, username: uid, friends: friends);

class _SlowFriends extends FakeFriendsRepository {
  final gate = Completer<void>();

  @override
  Future<void> sendRequest({required String from, required String to}) async {
    await gate.future;
    return super.sendRequest(from: from, to: to);
  }
}

class _FailingSearch extends FakeUserRepository {
  @override
  Future<List<UserProfile>> searchByUsername(String prefix, {int limit = 20}) =>
      Future.error(Exception('FAILED_PRECONDITION: index'));
}

void main() {
  late FakeUserRepository users;
  late FakeFriendsRepository friendsRepo;
  late FakeNotificationRepository notifications;

  FriendsStore store({FakeFriendsRepository? friends}) => FriendsStore(
    friends: friends ?? friendsRepo,
    users: users,
    notifications: notifications,
  )..attach('me');

  setUp(() {
    users = FakeUserRepository()
      ..put(_p('me', friends: ['bob']))
      ..put(_p('bob'))
      ..put(_p('dave'))
      ..put(_p('erin'));
    friendsRepo = FakeFriendsRepository();
    notifications = FakeNotificationRepository();
  });

  group('FriendsStore', () {
    test('relations follow the profile and both request directions', () async {
      await friendsRepo.sendRequest(from: 'me', to: 'erin');
      await friendsRepo.sendRequest(from: 'dave', to: 'me');
      final s = store();
      await pumpEventQueue();

      expect(s.relationTo('me'), FriendRelation.self);
      expect(s.relationTo('bob'), FriendRelation.friends);
      expect(s.relationTo('erin'), FriendRelation.requestSent);
      expect(
        s.relationTo('dave'),
        FriendRelation.requestReceived,
        reason: 'a received request is not "pending" (BUG-070)',
      );
      expect(s.incomingCount, 1);
    });

    test('accept writes as the receiver; reject and cancel by id', () async {
      final s = store();
      await pumpEventQueue();
      expect(await s.acceptRequest('dave'), isNull);
      expect(await s.rejectRequest('erin'), isNull);
      expect(await s.cancelRequest('bob'), isNull);
      expect(friendsRepo.calls, [
        'accept:dave->me',
        'reject:erin->me',
        'cancel:me->bob',
      ]);
    });

    test('a second tap while a request is running is ignored', () async {
      final slow = _SlowFriends();
      final s = store(friends: slow);
      await pumpEventQueue();
      final first = s.sendRequest('dave');
      expect(s.isBusy('dave'), isTrue);
      await s.sendRequest('dave');
      slow.gate.complete();
      await first;
      expect(slow.calls, ['send:me->dave']);
      expect(s.isBusy('dave'), isFalse);
    });

    test('follow also leaves the in-app notification', () async {
      final s = store();
      await pumpEventQueue();
      expect(await s.follow('bob'), isNull);
      expect(await s.isFollowing('bob'), isTrue);
      expect(notifications.calls, ['follow:me->bob']);
      expect(await s.unfollow('bob'), isNull);
      expect(await s.isFollowing('bob'), isFalse);
    });

    test('detach forgets everything', () async {
      final s = store();
      await pumpEventQueue();
      s.dismissSuggestion('dave');
      s.detach();
      expect(s.friendIds, isEmpty);
      expect(s.dismissed, isEmpty);
      expect(s.uid, isNull);
    });
  });

  group('UserDirectory', () {
    test('lookups in the same frame share one query (BUG-073)', () async {
      final d = UserDirectory(users);
      expect(d.profile('bob'), isNull);
      expect(d.profile('dave'), isNull);
      expect(d.profile('ghost'), isNull);
      await pumpEventQueue();
      expect(users.getProfilesCalls, 1);
      expect(d.profile('bob')!.name, 'bob');
      expect(d.isResolved('ghost'), isTrue);
      expect(d.profile('ghost'), isNull);
      expect(users.getProfilesCalls, 1, reason: 'cached, misses included');
    });

    test('detach clears the cache', () async {
      final d = UserDirectory(users)..attach('me');
      await d.resolveAll(['bob']);
      d.detach();
      expect(d.isResolved('bob'), isFalse);
    });
  });

  group('FriendSuggestionsController', () {
    test('normalises the query', () {
      expect(FriendSuggestionsController.normalize(' @Dave '), 'dave');
    });

    test('searches by lower-case prefix and primes the directory', () async {
      final d = UserDirectory(users);
      final c = FriendSuggestionsController(
        users: users,
        directory: d,
        debounce: Duration.zero,
      );
      await pumpEventQueue();
      expect(c.results, hasLength(4));
      c.search('DA');
      await Future<void>.delayed(Duration.zero);
      await pumpEventQueue();
      expect(c.results.map((u) => u.uid), ['dave']);
      expect(d.isResolved('dave'), isTrue);
      expect(users.getProfilesCalls, 0);
      c.dispose();
    });

    test('a failing query shows an error, not an empty list', () async {
      final c = FriendSuggestionsController(
        users: _FailingSearch(),
        directory: UserDirectory(users),
      );
      await pumpEventQueue();
      expect(c.error, isA<AppFailure>());
      expect(c.isLoading, isFalse);
      c.dispose();
    });
  });

  group('PinnedFriendsController', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('stale pins are ignored and the order is stable', () async {
      users.put(_p('me', friends: ['bob', 'dave', 'erin', 'zed']));
      final prefs = PreferencesStore();
      await prefs.setPinnedFriends('me', ['gone', 'erin']);
      final s = store();
      final c = PinnedFriendsController(
        friends: s,
        prefs: prefs,
        random: Random(1),
      );
      await pumpEventQueue();

      expect(c.isLoading, isFalse);
      expect(c.pinnedUids, ['erin'], reason: 'former friend dropped');
      final shown = c.displayFriends;
      expect(shown, hasLength(3));
      expect(shown.first, 'erin');
      s.dismissSuggestion('x'); // Unrelated change: no reshuffle.
      expect(c.displayFriends, shown);

      await c.setPinnedFriends(['bob', 'gone']);
      expect(await prefs.pinnedFriends('me'), ['bob']);
      expect(c.displayFriends.first, 'bob');
      c.dispose();
    });
  });

  test('friends with an empty name are grouped under # (BUG-077)', () {
    final grouped = groupFriendsByInitial([
      _p('a', name: ''),
      _p('b', name: 'bob'),
    ], '');
    expect(grouped.keys, containsAll(['#', 'B']));
  });
}

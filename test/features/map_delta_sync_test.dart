import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/services/location_service.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/map/current_location.dart';
import 'package:later/features/map/engine/map_camera_memory.dart';
import 'package:later/features/map/map_controller.dart';
import 'package:later/features/map/map_delta_sync.dart';
import 'package:later/features/map/map_pin_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_repositories.dart';

final _synced = DateTime.utc(2026, 10, 19, 12);

/// The same moment, whatever its time zone.
Matcher _at(DateTime d) =>
    predicate<DateTime?>((v) => v != null && v.isAtSameMomentAs(d), 'at $d');

Capsule _capsule(
  String id, {
  String owner = 'friend',
  CapsulePrivacy privacy = CapsulePrivacy.friends,
  DateTime? createdAt,
}) => Capsule(
  id: id,
  ownerId: owner,
  title: 'Title of $id',
  privacy: privacy,
  color: CapsuleColor.blue,
  location: const GeoPosition(52.23, 21.01),
  createdAt: createdAt,
);

/// The friends' full list held until the test sends it (a new friend's).
class _Capsules extends FakeCapsuleRepository {
  final friendsFull = StreamController<List<Capsule>>.broadcast();
  List<String>? fullFor;

  @override
  Stream<List<Capsule>> watchFriends(List<String> friendIds) {
    fullFor = friendIds;
    return friendsFull.stream;
  }

  Future<void> close() async {
    await friendsFull.close();
    await closeSync();
  }
}

class _NoLocation extends LocationService {
  @override
  Future<LocationAvailability> availability({bool request = false}) async =>
      LocationAvailability.denied;

  @override
  Future<GeoPosition?> lastKnownPosition() async => null;

  @override
  Stream<GeoPosition> positions({int distanceFilter = 10}) =>
      const Stream.empty();
}

StoredMap _kept({List<String> friends = const ['friend']}) => StoredMap(
  pins: [
    StoredPin(_capsule('kept-friends'), PinSource.friends),
    StoredPin(_capsule('kept-of-old-friend', owner: 'old'), PinSource.friends),
    StoredPin(
      _capsule('kept-public', owner: 'x', privacy: CapsulePrivacy.public),
      PinSource.public,
    ),
  ],
  syncedTo: _synced,
  friendIds: friends,
  bandLatitude: 52.2,
);

void main() {
  late _Capsules capsules;
  setUp(() => capsules = _Capsules());
  tearDown(() => capsules.close());

  group('the sync', () {
    MapDeltaSync sync({
      required List<String> friends,
      StoredMap? stored,
      void Function(String)? failed,
      int limit = 500,
    }) => MapDeltaSync(
      capsules: capsules,
      stored: stored ?? _kept(),
      friendIds: friends,
      onChanged: () {},
      onFailed: failed ?? (reason) => fail('failed: $reason'),
      limit: limit,
    )..start();

    test('asks only for what is newer than what the phone kept', () async {
      final s = sync(friends: ['friend']);
      expect(capsules.sinceAsked.keys, ['friends', 'public', 'deletions']);
      for (final at in capsules.sinceAsked.values) {
        expect(at, _at(_synced));
      }
      expect(capsules.friendsSinceIds, ['friend']);
      expect(capsules.fullFor, isNull, reason: 'no friend added since');
      s.dispose();
    });

    test('the kept ones, the new ones, none deleted; synced to the newest '
        'change', () async {
      final s = sync(friends: ['friend']);
      final created = _synced.add(const Duration(minutes: 5));
      final deleted = _synced.add(const Duration(minutes: 9));
      capsules.friendsSince.add([_capsule('new-friends', createdAt: created)]);
      capsules.publicSince.add([
        _capsule(
          'new-public',
          owner: 'y',
          privacy: CapsulePrivacy.public,
          createdAt: created,
        ),
      ]);
      capsules.deletionsSince.add([CapsuleDeletion('kept-public', deleted)]);
      await pumpEventQueue();
      expect(s.friends.map((c) => c.id), ['kept-friends', 'new-friends']);
      expect(s.public.map((c) => c.id), ['new-public']);
      expect(s.friendsAnswered, isTrue);
      expect(s.publicAnswered, isTrue);
      expect(s.syncedTo, _at(deleted));
      s.dispose();
    });

    test("a friend added since: their capsules read in full; a removed one's "
        'go', () async {
      final s = sync(friends: ['friend', 'new-friend']);
      expect(capsules.fullFor, ['new-friend']);
      expect(capsules.friendsSinceIds, ['friend']);
      capsules.friendsSince.add([]);
      await pumpEventQueue();
      expect(s.friendsAnswered, isFalse, reason: "the new friend's to come");
      capsules.friendsFull.add([_capsule('old-of-new', owner: 'new-friend')]);
      await pumpEventQueue();
      expect(s.friendsAnswered, isTrue);
      expect(s.friends.map((c) => c.id), ['kept-friends', 'old-of-new']);
      s.dispose();
    });

    test('an error or a full answer: everything is read again', () async {
      final reasons = <String>[];
      final s = sync(friends: ['friend'], failed: reasons.add, limit: 2);
      capsules.publicSince.add([
        _capsule('p1', privacy: CapsulePrivacy.public),
        _capsule('p2', privacy: CapsulePrivacy.public),
      ]);
      await pumpEventQueue();
      expect(reasons, ['public at their limit']);
      // Nothing more from it once it gave up.
      capsules.friendsSince.add([_capsule('late')]);
      await pumpEventQueue();
      expect(s.friends.map((c) => c.id), isNot(contains('late')));

      final failing = <String>[];
      sync(friends: ['friend'], failed: failing.add);
      capsules.deletionsSince.addError(
        StateError('failed-precondition: missing index'),
      );
      await pumpEventQueue();
      expect(failing.single, contains('missing index'));
    });
  });

  group('the map with it', () {
    late FakeAuthRepository auth;
    late FakeUserRepository users;
    late SessionController session;
    late Directory dir;

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('map_sync_');
      auth = FakeAuthRepository();
      users = FakeUserRepository()
        ..put(
          const UserProfile(
            uid: 'u1',
            name: 'A',
            username: 'a',
            friends: ['friend'],
          ),
        );
      session = SessionController(auth: auth, users: users)..start();
      auth.emit('u1');
      await pumpEventQueue();
      SharedPreferences.setMockInitialValues({
        'u:u1:${MapCameraMemory.key}': MapCameraMemory.format(52.2, 21, 14),
      });
    });

    tearDown(() async {
      session.dispose();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    Future<(MapController, MapPinStore)> started() async {
      final mine = dir;
      final saved = MapPinStore(directory: () async => mine)..attach('u1');
      await saved.save('u1', _kept());
      final pins = MapPinStore(directory: () async => mine)..attach('u1');
      final prefs = PreferencesStore();
      await prefs.init();
      final map = MapController(
        capsules: capsules,
        location: _NoLocation(),
        currentLocation: CurrentLocation(),
        session: session,
        prefs: prefs,
        pinStore: pins,
        groupsMarkers: false,
        deltaSync: true,
      );
      unawaited(map.start());
      await pins.settled;
      await pumpEventQueue();
      return (map, pins);
    }

    test('opens with what it kept, merges the changes, never reads the '
        'friends or the band in full', () async {
      final (map, pins) = await started();
      expect(capsules.sinceAsked['friends'], _at(_synced));
      capsules
        ..emitOwn([])
        ..emitCoAuthored([]);
      capsules.friendsSince.add([
        _capsule(
          'new-friends',
          createdAt: _synced.add(const Duration(hours: 1)),
        ),
      ]);
      capsules.publicSince.add([]);
      capsules.deletionsSince.add([CapsuleDeletion('kept-public', _synced)]);
      await pumpEventQueue();
      expect(map.allAnswered, isTrue);
      expect(map.visibleCapsules.map((c) => c.id).toSet(), {
        'kept-friends',
        'new-friends',
      });
      // A kept pin opens through the server; a new one as it came.
      expect(map.isStoredOnly('kept-friends'), isTrue);
      expect(map.isStoredOnly('new-friends'), isFalse);
      map.dispose();
      await pins.settled;
      final next = await (MapPinStore(
        directory: () async => dir,
      )..attach('u1')).read('u1');
      expect(next.syncedTo, _at(_synced.add(const Duration(hours: 1))));
      expect(next.friendIds, ['friend']);
    });

    test('a friend change during the session: everything read', () async {
      final (map, pins) = await started();
      users.put(
        const UserProfile(
          uid: 'u1',
          name: 'A',
          username: 'a',
          friends: ['friend', 'someone'],
        ),
      );
      await pumpEventQueue();
      expect(capsules.fullFor, ['friend', 'someone']);
      map.dispose();
      await pins.settled;
    });
  });
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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
import 'package:later/features/map/map_pin_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_repositories.dart';

Capsule _capsule(
  String id, {
  String owner = 'u1',
  CapsulePrivacy privacy = CapsulePrivacy.private,
  CapsuleColor color = CapsuleColor.green,
  DateTime? openAt,
  List<String> coAuthors = const [],
  bool pending = false,
}) => Capsule(
  id: id,
  ownerId: owner,
  title: 'Title of $id',
  description: 'never stored',
  imageUrl: 'https://example.test/$id.jpg',
  privacy: privacy,
  color: color,
  location: GeoPosition(52.2 + id.length / 1000, 21.01),
  openAt: openAt,
  coAuthors: coAuthors,
  pending: pending,
);

/// Every source of the map held until the test lets it answer.
class _HeldCapsules extends FakeCapsuleRepository {
  final ownSource = StreamController<List<Capsule>>.broadcast();
  final coSource = StreamController<List<Capsule>>.broadcast();
  final friendsSource = StreamController<List<Capsule>>.broadcast();
  final publicSource = StreamController<List<Capsule>>.broadcast();

  Future<void> close() async {
    await ownSource.close();
    await coSource.close();
    await friendsSource.close();
    await publicSource.close();
  }

  @override
  Stream<List<Capsule>> watchOwn(String uid) => ownSource.stream;

  @override
  Stream<List<Capsule>> watchCoAuthored(String uid) => coSource.stream;

  @override
  Stream<List<Capsule>> watchFriends(List<String> friendIds) =>
      friendsSource.stream;

  @override
  Stream<List<Capsule>> watchPublicInBand(
    double minLat,
    double maxLat, {
    int limit = 300,
  }) => publicSource.stream;
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

void main() {
  late Directory dir;
  final stores = <MapPinStore>[];

  setUp(() => dir = Directory.systemTemp.createTempSync('map_pins_'));
  tearDown(() async {
    // Writes still under way (a map closing saves) end first.
    for (final s in stores) {
      await s.settled;
    }
    stores.clear();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  /// A store in this test's directory (not the next test's, should a
  /// write still be under way).
  MapPinStore store() {
    final mine = dir;
    final store = MapPinStore(directory: () async => mine);
    stores.add(store);
    return store;
  }

  group('the format', () {
    test('keeps what the marker, the filter and the rule need, and no '
        'more', () {
      final opens = DateTime(2027, 1, 2, 3, 4);
      final pins = MapPinStore.decode(
        MapPinStore.encode([
          StoredPin(_capsule('a', color: CapsuleColor.purple), PinSource.own),
          StoredPin(
            _capsule(
              'b',
              owner: 'friend',
              privacy: CapsulePrivacy.friends,
              openAt: opens,
            ),
            PinSource.friends,
          ),
          StoredPin(
            _capsule('c', owner: 'friend', coAuthors: ['u1', 'x']),
            PinSource.co,
          ),
        ]),
        uid: 'u1',
      );
      expect(pins.map((p) => p.capsule.id), ['a', 'b', 'c']);
      expect(pins.map((p) => p.source), [
        PinSource.own,
        PinSource.friends,
        PinSource.co,
      ]);
      final b = pins[1].capsule;
      expect(b.ownerId, 'friend');
      expect(b.privacy, CapsulePrivacy.friends);
      expect(b.openAt, opens);
      expect(b.location!.latitude, closeTo(52.201, 1e-9));
      expect(pins[0].capsule.color, CapsuleColor.purple);
      // Only the signed-in user is known as a co-author.
      expect(pins[2].capsule.coAuthors, ['u1']);
      // Nothing to show: no title, photo or text.
      for (final p in pins) {
        expect(p.capsule.title, isEmpty);
        expect(p.capsule.imageUrl, isNull);
        expect(p.capsule.description, isNull);
      }
    });

    test('anything else reads as no pins', () {
      final good = MapPinStore.encode([
        StoredPin(_capsule('a'), PinSource.own),
      ]);
      expect(MapPinStore.decode(Uint8List(0), uid: 'u1'), isEmpty);
      expect(
        MapPinStore.decode(Uint8List.fromList([1, 2, 3, 4, 5]), uid: 'u1'),
        isEmpty,
      );
      expect(
        MapPinStore.decode(Uint8List.sublistView(good, 0, 20), uid: 'u1'),
        isEmpty,
      );
    });

    test('5,000 pins read back quickly', () {
      final bytes = MapPinStore.encode([
        for (var i = 0; i < 5000; i++)
          StoredPin(
            _capsule('capsule-$i', owner: 'owner-${i % 300}'),
            PinSource.values[i % 4],
          ),
      ]);
      final watch = Stopwatch()..start();
      final pins = MapPinStore.decode(bytes, uid: 'u1');
      watch.stop();
      expect(pins, hasLength(5000));
      expect(bytes.length, lessThan(5000 * 60));
      // The phone's number is in docs/map/COLD_START.md; this only guards
      // against a slow format.
      expect(watch.elapsedMilliseconds, lessThan(200));
    });
  });

  group('the account', () {
    test('its own pins only, gone at sign-out and when another signs '
        'in', () async {
      final pins = store()..attach('u1');
      await pins.save('u1', [StoredPin(_capsule('a'), PinSource.own)]);
      expect(File('${dir.path}/u1.bin').existsSync(), isTrue);

      final next = store()..attach('u1');
      expect((await next.pins('u1')).single.capsule.id, 'a');
      expect(await next.pins('u2'), isEmpty);

      // Another account on this phone: the first one's pins are removed.
      final other = store()..attach('u2');
      await other.settled;
      expect(File('${dir.path}/u1.bin').existsSync(), isFalse);
      await other.save('u2', [StoredPin(_capsule('b'), PinSource.own)]);

      // Its session ends (sign-out, a revoked token): deleted.
      other.detach();
      await other.settled;
      expect(File('${dir.path}/u2.bin').existsSync(), isFalse);
    });
  });

  group('the map', () {
    late FakeAuthRepository auth;
    late FakeUserRepository users;
    late SessionController session;
    late _HeldCapsules capsules;
    late PreferencesStore prefs;

    setUp(() async {
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
      capsules = _HeldCapsules();
      SharedPreferences.setMockInitialValues({
        'u:u1:${MapCameraMemory.key}': MapCameraMemory.format(52.2, 21, 14),
      });
      prefs = PreferencesStore();
      await prefs.init();
    });

    tearDown(() async {
      session.dispose();
      await capsules.close();
    });

    Future<MapController> started(MapPinStore pins) async {
      final map = MapController(
        capsules: capsules,
        location: _NoLocation(),
        currentLocation: CurrentLocation(),
        session: session,
        prefs: prefs,
        pinStore: pins,
        groupsMarkers: false,
      );
      unawaited(map.start());
      // The file is read on the disk, not in a microtask.
      await pins.settled;
      await pumpEventQueue();
      return map;
    }

    Future<MapPinStore> storeHolding(List<StoredPin> pins) async {
      final saved = store()..attach('u1');
      await saved.save('u1', pins);
      return store()..attach('u1');
    }

    List<String> shown(MapController map) =>
        map.visibleCapsules.map((c) => c.id).toList()..sort();

    final last = [
      StoredPin(_capsule('mine'), PinSource.own),
      StoredPin(_capsule('deleted'), PinSource.own),
      StoredPin(
        _capsule(
          'friends-only',
          owner: 'friend',
          privacy: CapsulePrivacy.friends,
        ),
        PinSource.friends,
      ),
      StoredPin(
        _capsule('public', owner: 'someone', privacy: CapsulePrivacy.public),
        PinSource.public,
      ),
      StoredPin(
        _capsule('made-together', owner: 'friend', coAuthors: ['u1']),
        PinSource.co,
      ),
    ];

    test('shows the last pins before any source answers, and each '
        "source's answer replaces its own", () async {
      final map = await started(await storeHolding(last));
      expect(shown(map), [
        'deleted',
        'friends-only',
        'made-together',
        'mine',
        'public',
      ]);
      expect(map.complete, isTrue);
      expect(map.allAnswered, isFalse);
      expect(map.isStoredOnly('mine'), isTrue);

      // Deleted on another phone: gone with the owner's answer.
      capsules.ownSource.add([_capsule('mine')]);
      await pumpEventQueue();
      expect(shown(map), ['friends-only', 'made-together', 'mine', 'public']);
      expect(map.isStoredOnly('mine'), isFalse);

      // Made private (or the friend blocked this user): not in the answer.
      capsules.friendsSource.add([]);
      capsules.publicSource.add([]);
      await pumpEventQueue();
      expect(shown(map), ['made-together', 'mine']);

      capsules.coSource.add([]);
      await pumpEventQueue();
      expect(shown(map), ['mine']);
      expect(map.allAnswered, isTrue);
      map.dispose();
    });

    test(
      'a friend removed since: their friends-only pins never show',
      () async {
        users.put(const UserProfile(uid: 'u1', name: 'A', username: 'a'));
        await pumpEventQueue();
        final map = await started(await storeHolding(last));
        expect(shown(map), isNot(contains('friends-only')));
        expect(shown(map), contains('public'));
        map.dispose();
      },
    );

    test('a stored pin opens only as the server has it now', () async {
      final map = await started(await storeHolding(last));
      expect(await map.freshCapsule('deleted'), isNull);
      capsules.byId = _capsule('mine');
      expect((await map.freshCapsule('mine'))!.title, 'Title of mine');
      // No longer visible to this user (now private, someone else's).
      capsules.byId = _capsule('public', owner: 'someone');
      expect(await map.freshCapsule('public'), isNull);
      map.dispose();
    });

    test('a capsule waiting to upload stays through the answers', () async {
      final map = await started(await storeHolding(last));
      capsules.ownSource.add([
        _capsule('mine'),
        _capsule('new', pending: true),
      ]);
      capsules.coSource.add([]);
      capsules.friendsSource.add([]);
      capsules.publicSource.add([]);
      await pumpEventQueue();
      expect(shown(map), ['mine', 'new']);
      map.dispose();
    });

    test('a first start without pins waits for every source', () async {
      final map = await started(store()..attach('u1'));
      expect(map.visibleCapsules, isEmpty);
      expect(map.complete, isFalse);
      capsules.ownSource.add([_capsule('mine')]);
      await pumpEventQueue();
      expect(map.complete, isFalse);
      map.dispose();
    });

    test('keeps what every source answered, and only that', () async {
      final pins = store()..attach('u1');
      final map = await started(pins);
      capsules.ownSource.add([_capsule('mine')]);
      capsules.coSource.add([]);
      capsules.friendsSource.add([
        _capsule(
          'friends-only',
          owner: 'friend',
          privacy: CapsulePrivacy.friends,
        ),
        // Not this user's to see: never kept.
        _capsule('private', owner: 'friend'),
      ]);
      capsules.publicSource.add([
        _capsule('public', owner: 'someone', privacy: CapsulePrivacy.public),
        // Also the user's own: kept as the owner's.
        _capsule('mine', privacy: CapsulePrivacy.public),
      ]);
      await pumpEventQueue();
      // Written a moment after the last change.
      await Future<void>.delayed(const Duration(milliseconds: 2200));
      final kept = await (store()..attach('u1')).pins('u1');
      expect(
        {for (final p in kept) p.capsule.id: p.source},
        {
          'public': PinSource.public,
          'friends-only': PinSource.friends,
          'mine': PinSource.own,
        },
      );
      map.dispose();
    });
  });
}

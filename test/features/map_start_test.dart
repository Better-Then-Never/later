import 'dart:async';

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
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_repositories.dart';

/// A phone whose location answers only when the test says so.
class _HeldLocation extends LocationService {
  final calls = <String>[];
  final lastKnown = Completer<GeoPosition?>();

  @override
  Future<LocationAvailability> availability({bool request = false}) async {
    calls.add('availability');
    return LocationAvailability.available;
  }

  @override
  Future<GeoPosition?> lastKnownPosition() {
    calls.add('lastKnown');
    return lastKnown.future;
  }

  @override
  Future<GeoPosition?> currentPosition({
    Duration timeout = const Duration(seconds: 8),
    bool request = false,
  }) {
    calls.add('current');
    return Completer<GeoPosition?>().future;
  }

  @override
  Stream<GeoPosition> positions({int distanceFilter = 10}) =>
      const Stream.empty();
}

Capsule _own(int i) => Capsule(
  id: 'own-$i',
  ownerId: 'u1',
  title: 't',
  privacy: CapsulePrivacy.private,
  color: CapsuleColor.green,
  location: GeoPosition(52.2 + i / 100, 21.0),
);

void main() {
  late FakeAuthRepository auth;
  late SessionController session;
  late FakeCapsuleRepository capsules;
  late _HeldLocation location;

  Future<PreferencesStore> prefsWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = PreferencesStore();
    await prefs.init();
    return prefs;
  }

  setUp(() async {
    auth = FakeAuthRepository();
    final users = FakeUserRepository()
      ..put(const UserProfile(uid: 'u1', name: 'A', username: 'a'));
    session = SessionController(auth: auth, users: users)..start();
    auth.emit('u1');
    await pumpEventQueue();
    capsules = FakeCapsuleRepository()
      ..own = [for (var i = 0; i < 3; i++) _own(i)];
    location = _HeldLocation();
  });

  tearDown(() => session.dispose());

  MapController controller(PreferencesStore prefs) => MapController(
    capsules: capsules,
    location: location,
    currentLocation: CurrentLocation(),
    session: session,
    prefs: prefs,
    groupsMarkers: false,
  );

  Future<PreferencesStore> saved() => prefsWith({
    'u:u1:${MapCameraMemory.key}': MapCameraMemory.format(52.23, 21.01, 14.5),
  });

  test('opens on the user, at the zoom the map was last left at; the '
      'capsules first (M-06)', () async {
    final map = controller(await saved());
    unawaited(map.start());
    await pumpEventQueue();
    // Asked for before the position: own, co-authored and friends'.
    expect(map.state, MapLoadState.loading);
    expect(map.visibleCapsules.map((c) => c.id), ['own-0', 'own-1', 'own-2']);

    location.lastKnown.complete(const GeoPosition(50.06, 19.94));
    await pumpEventQueue();
    expect(map.state, MapLoadState.ready);
    expect(map.initialCamera.latitude, 50.06);
    expect(map.initialCameraZoom, 14.5);
    // No fresh fix waited for: the last known one is enough.
    expect(location.calls, isNot(contains('current')));
    expect(map.allAnswered, isTrue);
    map.dispose();
  });

  test('no position on the phone: where the map last stopped', () async {
    final map = controller(await saved());
    unawaited(map.start());
    await pumpEventQueue();
    location.lastKnown.complete(null);
    await pumpEventQueue();
    expect(map.state, MapLoadState.ready);
    expect(map.initialCamera.latitude, 52.23);
    expect(map.usedFallbackCamera, isFalse);
    expect(location.calls, isNot(contains('current')));
    map.dispose();
  });

  test('the phone slow to answer: where the map last stopped, after a '
      'moment', () async {
    final map = controller(await saved());
    unawaited(map.start());
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(map.state, MapLoadState.ready);
    expect(map.initialCamera.latitude, 52.23);
    expect(map.initialCameraZoom, 14.5);
    map.dispose();
  });

  test('with nowhere saved it waits for a position, the capsules '
      'meanwhile', () async {
    final map = controller(await prefsWith({}));
    unawaited(map.start());
    await pumpEventQueue();

    expect(map.state, MapLoadState.loading);
    // Asked for before the location; the public ones need its latitude.
    expect(map.visibleCapsules, hasLength(3));
    expect(map.allAnswered, isFalse);

    location.lastKnown.complete(const GeoPosition(50.06, 19.94));
    await pumpEventQueue();
    expect(map.state, MapLoadState.ready);
    expect(map.initialCamera.latitude, 50.06);
    expect(map.initialCameraZoom, MapController.initialZoom);
    expect(map.allAnswered, isTrue);
    map.dispose();
  });
}

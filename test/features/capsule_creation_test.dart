import 'dart:io';

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/services/location_service.dart';
import 'package:later/features/capsules/creation/capsule_creation_controller.dart';
import 'package:later/features/map/current_location.dart';

import '../fakes/fake_repositories.dart';
import 'package:flutter/services.dart';
import 'package:later/data/services/gallery_service.dart';
import 'package:later/features/capsules/creation/widgets/pin_picker_sheet.dart';
import 'package:later/features/capsules/creation/creation_draft.dart';

class _FakeLocation extends LocationService {
  _FakeLocation(this.position);

  GeoPosition? position;

  @override
  Future<GeoPosition?> currentPosition({
    Duration timeout = const Duration(seconds: 8),
    bool request = false,
  }) async => position;
}

class _SlowCapsules extends FakeCapsuleRepository {
  final gate = Completer<void>();

  @override
  Future<Capsule> create(CapsuleDraft draft) async {
    await gate.future;
    return super.create(draft);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CapsuleCreationController build(
    FakeCapsuleRepository repo, {
    GeoPosition? known,
    GeoPosition? fresh,
    CapsulePrivacy? privacy,
  }) {
    final current = CurrentLocation()..update(known);
    return CapsuleCreationController(
      ownerId: 'me',
      imagePath: 'does/not/exist.jpg',
      capsules: repo,
      location: _FakeLocation(fresh),
      currentLocation: current,
      initialPrivacy: privacy,
    );
  }

  test(
    'saves a draft with trimmed text, defaults and the known position',
    () async {
      final repo = FakeCapsuleRepository();
      final c = build(repo, known: const GeoPosition(1, 2));
      c.titleController.text = '  ';
      c.descriptionController.text = '  hello ';
      c
        ..color = CapsuleColor.blue
        ..privacy = CapsulePrivacy.private;
      expect(await c.save(), isNull);
      final draft = repo.created.single;
      expect(draft.title, 'Capsule', reason: 'empty title falls back');
      expect(draft.description, 'hello');
      expect(draft.color, CapsuleColor.blue);
      expect(draft.privacy, CapsulePrivacy.private);
      expect(draft.location, const GeoPosition(1, 2));
      c.dispose();
    },
  );

  test(
    'a second tap while saving does not create a second capsule (BUG-054)',
    () async {
      final repo = _SlowCapsules();
      final c = build(repo, known: const GeoPosition(1, 2));
      final first = c.save();
      expect(c.isSaving, isTrue);
      expect(await c.save(), isNull);
      repo.gate.complete();
      expect(await first, isNull);
      expect(repo.created, hasLength(1));
      c.dispose();
    },
  );

  test('approximate location and the capture time reach the draft', () async {
    final repo = FakeCapsuleRepository();
    final taken = DateTime(2026, 10, 17, 7, 5);
    final c = CapsuleCreationController(
      ownerId: 'me',
      imagePath: 'does/not/exist.jpg',
      capsules: repo,
      location: _FakeLocation(null),
      currentLocation: CurrentLocation()
        ..update(const GeoPosition(52.229676, 21.012229)),
      locationPrecision: LocationPrecision.approximate,
      capturedAt: taken,
    );
    expect(await c.save(), isNull);
    final draft = repo.created.single;
    expect(draft.location, const GeoPosition(52.23, 21.01));
    expect(draft.locationPrecision, LocationPrecision.approximate);
    expect(draft.capturedAt, taken);
    expect(draft.utcOffsetMinutes, taken.timeZoneOffset.inMinutes);
    c.dispose();
  });

  test(
    'high quality reaches the draft; the photo goes to the gallery',
    () async {
      final dir = await Directory.systemTemp.createTemp('later_gallery_test');
      addTearDown(() => dir.delete(recursive: true));
      final photo = File('${dir.path}/photo.jpg')..writeAsBytesSync([1, 2, 3]);
      final saved = <String>[];
      const channel = MethodChannel('test/gallery');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            final path = (call.arguments as Map)['path'] as String;
            // Still there: the gallery copy comes before the clean-up.
            if (File(path).existsSync()) saved.add(path);
            return true;
          });
      final repo = FakeCapsuleRepository();
      final c = CapsuleCreationController(
        ownerId: 'me',
        imagePath: photo.path,
        capsules: repo,
        location: _FakeLocation(null),
        currentLocation: CurrentLocation()..update(const GeoPosition(1, 2)),
        highQuality: true,
        saveToGallery: true,
        gallery: GalleryService(channel: channel),
      );
      expect(await c.save(), isNull);
      expect(repo.created.single.highQuality, isTrue);
      await pumpEventQueue();
      expect(saved, [photo.path]);
      expect(photo.existsSync(), isFalse, reason: 'temp photo deleted after');
      c.dispose();
    },
  );

  test(
    'a loop: frames removed and moved, its speed, two frames at least',
    () async {
      final repo = FakeCapsuleRepository();
      final c = CapsuleCreationController(
        ownerId: 'me',
        imagePath: 'f0.jpg',
        framePaths: const ['f0.jpg', 'f1.jpg', 'f2.jpg', 'f3.jpg'],
        capsules: repo,
        location: _FakeLocation(null),
        currentLocation: CurrentLocation()..update(const GeoPosition(1, 2)),
      );
      c.moveFrame(3, 0); // f3 first
      expect(c.framePaths, ['f3.jpg', 'f0.jpg', 'f1.jpg', 'f2.jpg']);
      expect(c.imagePath, 'f3.jpg', reason: 'the first frame is the picture');
      c.moveFrame(0, 2);
      expect(c.framePaths, ['f0.jpg', 'f3.jpg', 'f1.jpg', 'f2.jpg']);
      c
        ..removeFrame(1)
        ..removeFrame(1);
      expect(c.framePaths, ['f0.jpg', 'f2.jpg']);
      expect(c.canRemoveFrame, isFalse);
      c.removeFrame(0);
      expect(c.framePaths, hasLength(2), reason: 'still a loop');
      c.frameDelayMs = 150;
      expect(await c.save(), isNull);
      final draft = repo.created.single;
      expect(draft.framePaths, ['f0.jpg', 'f2.jpg']);
      expect(draft.imagePath, 'f0.jpg');
      expect(draft.frameDelayMs, 150);
      c.dispose();
    },
  );

  test('the circle the pin may move in is 1 km round, closed', () {
    const here = GeoPosition(52.2297, 21.0122);
    final ring = PinPickerSheet.ring(here, 1000);
    expect(ring, hasLength(257));
    expect(ring.last, ring.first, reason: 'a closed GeoJSON ring');
    for (final [lng, lat] in ring) {
      expect(
        Geolocator.distanceBetween(here.latitude, here.longitude, lat, lng),
        closeTo(1000, 5),
      );
    }
  });

  test('the pin moves within 1 km of where the phone is', () async {
    const here = GeoPosition(52.2297, 21.0122);
    // 0.005° north is about 556 m: allowed as it is.
    const near = GeoPosition(52.2347, 21.0122);
    expect(PinPickerSheet.clamp(here, near, 1000), near);
    // 0.05° north is about 5.6 km: pulled back onto the 1 km circle.
    final far = PinPickerSheet.clamp(
      here,
      const GeoPosition(52.2797, 21.0122),
      1000,
    );
    expect(far.latitude, closeTo(52.2387, 0.0003));
    expect(far.longitude, closeTo(21.0122, 0.00001));

    final repo = FakeCapsuleRepository();
    final c = build(repo, known: here)..movePin(near);
    expect(c.position, near);
    expect(c.here, here, reason: 'the phone stays the centre');
    expect(await c.save(), isNull);
    expect(repo.created.single.location, near);
    c.dispose();
  });

  test('left unfinished, it is kept; taken up again; gone once made', () async {
    final dir = await Directory.systemTemp.createTemp('later_drafts_test');
    addTearDown(() => dir.delete(recursive: true));
    final store = CreationDraftStore(directory: () async => dir);
    final shot = File('${dir.path}/camera.jpg')..writeAsBytesSync([1, 2, 3]);
    final repo = FakeCapsuleRepository();
    final first = CapsuleCreationController(
      ownerId: 'me',
      imagePath: shot.path,
      capsules: repo,
      location: _FakeLocation(null),
      currentLocation: CurrentLocation()..update(const GeoPosition(1, 2)),
      drafts: store,
    );
    first.titleController.text = 'Half done';
    first
      ..color = CapsuleColor.blue
      ..movePin(const GeoPosition(1.001, 2));
    // Leaving the page keeps what was there at once.
    first.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final kept = await store.load('me');
    expect(kept, isNotNull);
    expect(kept!.title, 'Half done');
    expect(kept.color, CapsuleColor.blue);
    expect(kept.pin, const GeoPosition(1.001, 2));
    expect(kept.imagePath, isNot(shot.path), reason: 'a copy of its own');
    expect(File(kept.imagePath).existsSync(), isTrue);

    final again = CapsuleCreationController(
      ownerId: 'me',
      imagePath: kept.imagePath,
      capsules: repo,
      location: _FakeLocation(null),
      currentLocation: CurrentLocation()..update(const GeoPosition(1, 2)),
      drafts: store,
      draft: kept,
    );
    expect(again.titleController.text, 'Half done');
    expect(again.color, CapsuleColor.blue);
    expect(again.position, const GeoPosition(1.001, 2));
    expect(await again.save(), isNull);
    expect(repo.created.single.location, const GeoPosition(1.001, 2));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await store.load('me'), isNull, reason: 'made: the draft goes');
    again.dispose();
  });

  test('co-authors reach the draft, five at most', () async {
    final repo = FakeCapsuleRepository();
    final c = build(repo, known: const GeoPosition(52.2297, 21.0122))
      ..coAuthors = ['a', 'b', 'c', 'd', 'e', 'f'];
    expect(c.coAuthors, ['a', 'b', 'c', 'd', 'e']);
    expect(await c.save(), isNull);
    expect(repo.created.single.coAuthors, ['a', 'b', 'c', 'd', 'e']);
    c.dispose();
  });

  test('comments, reactions and precision chosen per capsule', () async {
    final repo = FakeCapsuleRepository();
    final c = build(repo, known: const GeoPosition(52.2297, 21.0122))
      ..allowComments = false
      ..allowReactions = false
      ..approximateLocation = true;
    expect(await c.save(), isNull);
    final draft = repo.created.single;
    expect(draft.allowComments, isFalse);
    expect(draft.allowReactions, isFalse);
    expect(draft.locationPrecision, LocationPrecision.approximate);
    expect(draft.location, const GeoPosition(52.23, 21.01));
    c.dispose();
  });

  test('a 0,0 fix is not a place (F-18)', () async {
    expect(const GeoPosition(0, 0).isValid, isFalse);
    expect(const GeoPosition(0.00001, -0.00002).isValid, isFalse);
    expect(const GeoPosition(91, 10).isValid, isFalse);
    expect(const GeoPosition(0, 12).isValid, isTrue);
    final repo = FakeCapsuleRepository();
    final c = build(repo, fresh: const GeoPosition(0, 0));
    await pumpEventQueue();
    expect(c.position, isNull);
    expect(await c.save(), isA<ValidationFailure>());
    expect(repo.created, isEmpty);
    c.dispose();
  });

  test('looks the location up when none is known yet', () async {
    final repo = FakeCapsuleRepository();
    final c = build(repo, fresh: const GeoPosition(5, 6));
    await pumpEventQueue();
    expect(c.position, const GeoPosition(5, 6));
    expect(await c.save(), isNull);
    expect(repo.created.single.location, const GeoPosition(5, 6));
    c.dispose();
  });

  test('without any location it reports a clean error', () async {
    final repo = FakeCapsuleRepository();
    final c = build(repo);
    final failure = await c.save();
    expect(failure, isA<ValidationFailure>());
    expect(failure!.message, 'We could not detect your location');
    expect(repo.created, isEmpty);
    c.dispose();
  });

  test('the default title and errors follow the app language', () async {
    AppL10n.update(const Locale('de'));
    addTearDown(() => AppL10n.update(const Locale('en')));
    final repo = FakeCapsuleRepository();
    final noFix = build(repo);
    expect(
      (await noFix.save())!.message,
      'Wir konnten deinen Standort nicht ermitteln',
    );
    noFix.dispose();
    final c = build(repo, known: const GeoPosition(1, 2));
    expect(await c.save(), isNull);
    expect(repo.created.single.title, 'Kapsel');
    c.dispose();
  });

  test('open date presets: months keep the day or end on the last one', () {
    DateTime add(DateTime d, int m) =>
        CapsuleCreationController.addMonths(d, m);
    expect(add(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    expect(add(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
    expect(add(DateTime(2026, 12, 15), 1), DateTime(2027, 1, 15));
    expect(add(DateTime(2028, 2, 29), 12), DateTime(2029, 2, 28));

    final c = build(FakeCapsuleRepository(), known: const GeoPosition(1, 2));
    var changes = 0;
    c
      ..addListener(() => changes++)
      ..setOpenDate(DateTime(2030, 5, 17))
      ..clearOpenDate();
    expect(c.openAt, isNull, reason: 'open right away');
    c
      ..privacy = c.privacy
      ..color = c.color;
    expect(changes, 2, reason: 'choosing the same value changes nothing');
    c.dispose();
  });

  test('open date keeps the chosen day', () {
    final c = build(FakeCapsuleRepository(), known: const GeoPosition(0, 0));
    c.setOpenDate(DateTime(2030, 5, 17));
    expect(c.openAt!.year, 2030);
    expect(c.openAt!.month, 5);
    expect(c.openAt!.day, 17);
    c.dispose();
  });
}

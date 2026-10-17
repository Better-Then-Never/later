import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/services/location_service.dart';
import 'package:later/features/capsules/creation/capsule_creation_controller.dart';
import 'package:later/features/map/current_location.dart';

import '../fakes/fake_repositories.dart';

class _FakeLocation extends LocationService {
  _FakeLocation(this.position);

  GeoPosition? position;

  @override
  Future<GeoPosition?> currentPosition({
    Duration timeout = const Duration(seconds: 8),
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
      c.cycleColor();
      c.cyclePrivacy();
      expect(await c.save(), isNull);
      final draft = repo.created.single;
      expect(draft.title, 'Capsule', reason: 'empty title falls back');
      expect(draft.description, 'hello');
      expect(draft.color, CapsuleColor.blue);
      expect(
        draft.privacy,
        CapsulePrivacy.private,
        reason: 'public -> private',
      );
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

  test('open date keeps the chosen day', () {
    final c = build(FakeCapsuleRepository(), known: const GeoPosition(0, 0));
    c.setOpenDate(DateTime(2030, 5, 17));
    expect(c.openAt!.year, 2030);
    expect(c.openAt!.month, 5);
    expect(c.openAt!.day, 17);
    c.dispose();
  });
}

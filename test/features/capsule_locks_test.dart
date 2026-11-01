import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/firebase/firestore_mappers.dart';
import 'package:later/data/models/app_notification.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/features/capsules/opening/capsule_locks.dart';
import 'package:later/features/map/current_location.dart';
import 'package:later/data/services/geocoding_service.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/history/widgets/capsule_list_tile.dart';
import 'package:later/features/map/widgets/capsule_info_panel.dart';
import 'package:later/features/settings/device_settings_store.dart';
import 'package:provider/provider.dart';
import 'package:later/features/notifications/notification_texts.dart';
import 'package:later/l10n/gen/app_localizations_en.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/capsule_host.dart';
import '../helpers/test_app.dart';

final _now = DateTime(2026, 11, 1, 12);

/// An image of the sealed thumbnail (whatever size it is decoded at).
bool _showsThumb(Widget w) {
  if (w is! Image) return false;
  final image = w.image;
  final source = image is ResizeImage ? image.imageProvider : image;
  return source is CachedNetworkImageProvider && source.url == 'https://thumb';
}

const _spot = GeoPosition(52.2497, 21.0122);
const _content = CapsuleContent(
  imageUrl: 'https://img',
  thumbUrl: 'https://thumb',
  description: 'Hi',
);

Capsule _capsule({
  String id = 'c1',
  DateTime? openAt,
  OpenWhere where = OpenWhere.anywhere,
  bool sealed = true,
}) => Capsule(
  id: id,
  ownerId: 'bob',
  title: 'Lake',
  privacy: CapsulePrivacy.friends,
  color: CapsuleColor.blue,
  location: _spot,
  createdAt: _now.subtract(const Duration(days: 30)),
  openAt: openAt,
  openWhere: where,
  sealed: sealed,
);

/// [metres] north of the spot.
GeoPosition _north(double metres) =>
    GeoPosition(_spot.latitude + metres / 111320, _spot.longitude);

void main() {
  group('a sealed capsule on the phone (B3)', () {
    late FakeCapsuleRepository repo;
    late CapsuleLocks locks;

    setUp(() {
      repo = FakeCapsuleRepository()..sealedParts['c1'] = _content;
      locks = CapsuleLocks(repo, clock: () => _now)..attach('me');
    });
    tearDown(() => locks.detach());

    test('a dated one opens on its date, with its photo and words', () async {
      final waiting = _capsule(openAt: _now.add(const Duration(hours: 1)));
      expect(locks.mayOpen(waiting, _now), isFalse);
      expect(locks.resolve(waiting, _now).imageUrl, isNull);
      expect(repo.sealedReads, 0, reason: 'nothing is read before its date');

      final due = _capsule(openAt: _now.subtract(const Duration(minutes: 1)));
      expect(locks.mayOpen(due, _now), isTrue);
      var heard = 0;
      locks.addListener(() => heard++);
      // Not here yet: shown as it is while its part is read.
      expect(locks.resolve(due, _now).imageUrl, isNull);
      await pumpEventQueue();
      expect(heard, greaterThan(0));
      final shown = locks.resolve(due, _now);
      expect(shown.imageUrl, 'https://img');
      expect(shown.thumbUrl, 'https://thumb');
      expect(shown.description, 'Hi');
      expect(repo.sealedReads, 1, reason: 'read once');
      expect((await locks.fill(due)).imageUrl, 'https://img');
      expect(repo.sealedReads, 1);
    });

    test('a place one opens only once opened at its spot', () async {
      final place = _capsule(where: OpenWhere.here);
      expect(locks.waitsHere(place, _now), isTrue);
      expect(locks.mayOpen(place, _now), isFalse);
      expect((await locks.fill(place)).imageUrl, isNull);

      final opened = await locks.unlockHere(place, _north(40), accuracy: 8);
      expect(opened.imageUrl, 'https://img');
      expect(repo.unlocks.single.$1, 'c1');
      expect(locks.mayOpen(place, _now), isTrue);
      expect(locks.resolve(place, _now).imageUrl, 'https://img');
    });

    test('the unlocked list from the server opens place capsules', () async {
      final place = _capsule(where: OpenWhere.here);
      repo.setUnlocked({'c1'});
      await pumpEventQueue();
      expect(locks.isUnlocked('c1'), isTrue);
      expect(locks.mayOpen(place, _now), isTrue);
      locks.detach();
      expect(locks.isUnlocked('c1'), isFalse, reason: 'gone with the account');
    });

    test('a refused unlock says why and opens nothing', () async {
      repo.refuseUnlock = const CapsuleUnlockException(
        UnlockRefusal.tooFar,
        distance: 420,
      );
      final place = _capsule(where: OpenWhere.here);
      await expectLater(
        locks.unlockHere(place, _north(420)),
        throwsA(
          isA<CapsuleUnlockException>()
              .having((e) => e.reason, 'reason', UnlockRefusal.tooFar)
              .having((e) => e.distance, 'distance', 420),
        ),
      );
      expect(locks.mayOpen(place, _now), isFalse);
    });

    testWidgets('screens hear when a locked one comes to its date', (
      tester,
    ) async {
      final start = DateTime.now();
      final timed = CapsuleLocks(repo)..attach('me');
      addTearDown(timed.detach);
      final soon = _capsule(openAt: start.add(const Duration(seconds: 2)));
      var heard = 0;
      timed.addListener(() => heard++);
      expect(timed.resolve(soon, start).imageUrl, isNull);
      // The unlocked list arriving at sign-in is heard first.
      await tester.pump();
      heard = 0;
      await tester.pump(const Duration(seconds: 1));
      expect(heard, 0);
      await tester.pump(const Duration(seconds: 2));
      expect(heard, 1, reason: 'woken at its date, so a list shows it open');
    });

    test('a failed read is tried again later, not on every build', () async {
      repo.sealedError = StateError('offline');
      final due = _capsule(openAt: _now.subtract(const Duration(minutes: 1)));
      locks.resolve(due, _now);
      await pumpEventQueue();
      locks.resolve(due, _now);
      await pumpEventQueue();
      expect(repo.sealedReads, 1);
      expect(
        (await locks.fill(due)).imageUrl,
        isNull,
        reason: 'shown as it is',
      );
    });
  });

  group('written sealed', () {
    final draft = CapsuleDraft(
      ownerId: 'me',
      title: 'Lake',
      description: 'Hi',
      privacy: CapsulePrivacy.friends,
      color: CapsuleColor.red,
      location: _spot,
      imagePath: '/p.jpg',
      openAt: _now.add(const Duration(days: 365)),
      openWhere: OpenWhere.here,
    );

    test('a capsule for later or for here is sealed', () {
      expect(draft.sealedAt(_now), isTrue);
      const anytimeHere = CapsuleDraft(
        ownerId: 'me',
        title: 'T',
        privacy: CapsulePrivacy.friends,
        color: CapsuleColor.red,
        location: _spot,
        imagePath: '/p.jpg',
        openWhere: OpenWhere.here,
      );
      expect(anytimeHere.sealedAt(_now), isTrue);
      const now = CapsuleDraft(
        ownerId: 'me',
        title: 'T',
        privacy: CapsulePrivacy.friends,
        color: CapsuleColor.red,
        location: _spot,
        imagePath: '/p.jpg',
      );
      expect(now.sealedAt(_now), isFalse);
    });

    test('its photo and words go to the sealed part only', () {
      final capsule = FirestoreMappers.newCapsule(
        draft,
        imageUrl: 'https://img',
        thumbUrl: 'https://thumb',
        sealed: true,
      );
      for (final field in ['imageUrl', 'thumbUrl', 'frames', 'description']) {
        expect(capsule.containsKey(field), isFalse, reason: field);
      }
      expect(capsule['sealed'], isTrue);
      expect(capsule['openWhere'], 'here');
      expect(
        FirestoreMappers.sealedContent(
          draft,
          imageUrl: 'https://img',
          thumbUrl: 'https://thumb',
        ),
        {
          'imageUrl': 'https://img',
          'thumbUrl': 'https://thumb',
          'description': 'Hi',
        },
      );
      final read = FirestoreMappers.capsule('c', {
        ...capsule,
        'createdAt': Timestamp.fromDate(_now),
        'location': const GeoPoint(52.2497, 21.0122),
      });
      expect(read.sealed, isTrue);
      expect(read.opensHere, isTrue);
      expect(read.imageUrl, isNull);
    });
  });

  group('the map card of a place capsule (B4)', () {
    Future<CapsuleLocks> card(
      WidgetTester tester,
      Capsule capsule, {
      GeoPosition? at,
    }) async {
      final locks = CapsuleLocks(FakeCapsuleRepository())..attach('me');
      addTearDown(locks.detach);
      await tester.pumpWidget(
        capsuleHost(
          locks: locks,
          here: CurrentLocation()..update(at),
          child: testApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  height: CapsuleInfoPanel.minHeight,
                  child: CapsuleInfoPanel(capsule: capsule, onMoreInfo: (_) {}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return locks;
    }

    testWidgets('only here, no date: be there to open, how far, go there', (
      tester,
    ) async {
      await card(tester, _capsule(where: OpenWhere.here), at: _north(2400));
      expect(find.text('Be there to open'), findsOneWidget);
      expect(find.text('2.4 km away'), findsOneWidget);
      expect(find.text('Go there'), findsOneWidget);
      expect(find.text('Open'), findsNothing);
    });

    testWidgets('a date that came: ready to open; at the spot: open', (
      tester,
    ) async {
      final dated = _capsule(
        where: OpenWhere.here,
        openAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      await card(tester, dated, at: _north(350));
      expect(find.text('Ready to open'), findsOneWidget);
      expect(find.text('350 m away'), findsOneWidget);
      await card(tester, dated, at: _north(60));
      expect(find.text("You're here"), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('a date to come: the countdown, its day, here and how far', (
      tester,
    ) async {
      await card(
        tester,
        _capsule(
          where: OpenWhere.here,
          openAt: DateTime.now().add(const Duration(days: 3)),
        ),
        at: _north(800),
      );
      expect(find.textContaining('Opens in'), findsOneWidget);
      expect(find.textContaining(', here · 800 m away'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
    });

    testWidgets('location unknown: it says so', (tester) async {
      await card(tester, _capsule(where: OpenWhere.here));
      expect(find.text('Turn on location to see how far'), findsOneWidget);
    });
  });

  testWidgets('My capsules: a sealed one past its date shows its photo '
      'before the server releases it', (tester) async {
    final repo = FakeCapsuleRepository()..sealedParts['d1'] = _content;
    final locks = CapsuleLocks(repo)..attach('me');
    addTearDown(locks.detach);
    final due = _capsule(
      id: 'd1',
      openAt: DateTime.now().subtract(const Duration(minutes: 1)),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => GeocodingService()),
          ChangeNotifierProvider(
            create: (_) => DeviceSettingsStore(PreferencesStore()),
          ),
          ChangeNotifierProvider(create: (_) => CurrentLocation()),
          ChangeNotifierProvider<CapsuleLocks>.value(value: locks),
        ],
        child: testApp(
          home: Scaffold(
            body: CapsuleListTile(
              capsule: due,
              isFavorite: false,
              onFavoriteTap: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.byWidgetPredicate(_showsThumb), findsNothing);
    await tester.pump();
    await tester.pump();
    expect(repo.sealedReads, 1);
    // The tile now loads the sealed thumbnail (the lock stays only while
    // it loads, and in tests a network image never does).
    expect(find.byWidgetPredicate(_showsThumb), findsOneWidget);
  });

  test('"is open" and "is ready" in the notification list (F1, F2)', () {
    final l10n = AppLocalizationsEn();
    String text(NotificationType type, {String? place}) {
      final s = NotificationTexts.sentence(
        AppNotification(
          id: 'n',
          type: type,
          fromUserName: 'Bob',
          message: '',
          isRead: false,
          capsuleTitle: 'Lake',
          placeName: place,
        ),
        l10n: l10n,
      );
      return '${s.before}Bob${s.after}';
    }

    expect(
      text(NotificationType.capsuleOpen),
      'The capsule “Lake” from Bob is open',
    );
    expect(
      text(NotificationType.capsuleReady, place: 'Old Town'),
      "The capsule “Lake” from Bob is ready. It's waiting in Old Town",
    );
    expect(
      NotificationType.parse('capsuleReady'),
      NotificationType.capsuleReady,
    );
  });
}

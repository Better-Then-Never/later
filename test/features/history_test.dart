import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/services/geocoding_service.dart';
import 'package:later/features/history/favorites_store.dart';
import 'package:later/features/history/history_page.dart';
import 'package:later/features/history/history_controller.dart';
import 'package:later/features/history/own_capsules_store.dart';
import 'package:later/features/history/widgets/capsule_list_tile.dart';
import 'package:later/features/history/widgets/capsule_selection_action_bar.dart';
import 'package:later/features/map/current_location.dart';
import 'package:later/features/map/map_focus.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

Capsule _c(
  String id, {
  String? title,
  CapsuleColor color = CapsuleColor.red,
  CapsulePrivacy privacy = CapsulePrivacy.public,
  GeoPosition? location,
  DateTime? createdAt,
  DateTime? openAt,
}) => Capsule(
  id: id,
  ownerId: 'me',
  title: title ?? id,
  privacy: privacy,
  color: color,
  location: location,
  createdAt: createdAt,
  openAt: openAt,
);

class _FailingUsers extends FakeUserRepository {
  @override
  Future<void> setFavorite(String uid, String capsuleId, bool favorite) =>
      Future.error(const NetworkFailure('offline'));
}

void main() {
  group('HistoryController', () {
    final list = [
      _c(
        'b',
        title: 'Beach',
        color: CapsuleColor.blue,
        createdAt: DateTime(2024, 2),
        location: const GeoPosition(10, 0),
      ),
      _c(
        'a',
        title: 'Alps',
        privacy: CapsulePrivacy.private,
        createdAt: DateTime(2024, 1),
        location: const GeoPosition(1, 0),
      ),
      _c('n', title: 'No place'),
    ];
    List<String> ids(List<Capsule> l) => [for (final c in l) c.id];

    test('keeps the repository order (newest first) by default', () {
      expect(ids(HistoryController().apply(list)), ['b', 'a', 'n']);
    });

    test('searches titles case-insensitively', () {
      final c = HistoryController()..updateSearchQuery('  ALP ');
      expect(ids(c.apply(list)), ['a']);
    });

    test('combines colour, privacy and favourite filters', () {
      final c = HistoryController()..setColorFilter(CapsuleColor.red);
      expect(ids(c.apply(list)), ['a', 'n']);
      c.setPrivacyFilter(CapsulePrivacy.public);
      expect(ids(c.apply(list)), ['n']);
      c
        ..resetFilters()
        ..setFavoritesOnly(true);
      expect(ids(c.apply(list, favorites: {'b'})), ['b']);
      expect(c.activeFilterLabel(), 'Favorite');
    });

    test('date sorts put a pending timestamp (null) as newest', () {
      final c = HistoryController()..setSort(HistorySort.oldest);
      expect(ids(c.apply(list)), ['a', 'b', 'n']);
      c.setSort(HistorySort.newest);
      expect(ids(c.apply(list)), ['n', 'b', 'a']);
      expect(c.activeSortLabel(), 'From Newest');
    });

    test('distance sorts keep capsules without a location last', () {
      const here = GeoPosition(0, 0);
      final c = HistoryController()..setSort(HistorySort.closest);
      expect(ids(c.apply(list, from: here)), ['a', 'b', 'n']);
      c.setSort(HistorySort.farthest);
      expect(ids(c.apply(list, from: here)), ['b', 'a', 'n']);
      expect(ids(c.apply(list)), [
        'b',
        'a',
        'n',
      ], reason: 'unknown position: unchanged order');
    });

    test('button labels name the active sort and filters', () {
      final c = HistoryController();
      expect(c.activeSortLabel(), 'Sort By');
      expect(c.activeFilterLabel(), 'Filter By');
      c
        ..setSort(HistorySort.farthest)
        ..setColorFilter(CapsuleColor.purple)
        ..setPrivacyFilter(CapsulePrivacy.friends)
        ..setFavoritesOnly(true);
      expect(c.activeSortLabel(), 'From Farthest');
      expect(c.activeFilterLabel(), 'Purple · Friends · Favorite');
      c.resetAll();
      expect(c.activeSortLabel(), 'Sort By');
      expect(c.activeFilterLabel(), 'Filter By');
    });

    test('selection drops capsules that disappeared', () {
      final c = HistoryController()
        ..toggleSelection('a')
        ..toggleSelection('b');
      c.retainSelection(['b']);
      expect(c.selectedIds, {'b'});
      c.toggleSelection('b');
      expect(c.isSelectionMode, isFalse);
    });
  });

  group('OwnCapsulesStore', () {
    test('follows the session and deletes through the repository', () async {
      final repo = FakeCapsuleRepository()..own = [_c('x'), _c('y')];
      final store = OwnCapsulesStore(repo)..attach('me');
      await pumpEventQueue();
      expect(store.isLoaded, isTrue);
      expect(store.capsules, hasLength(2));

      expect(await store.delete(['y', 'unknown']), isNull);
      expect(repo.deleted, ['y']);

      store.detach();
      expect(store.capsules, isEmpty);
      expect(store.isLoaded, isFalse);
    });
  });

  group('FavoritesStore (BUG-066)', () {
    test('toggles optimistically and follows the profile', () async {
      final users = FakeUserRepository()
        ..put(const UserProfile(uid: 'me', name: 'Me', username: 'me'));
      final store = FavoritesStore(users)..attach('me');
      await pumpEventQueue();

      final pending = store.toggle('c1');
      expect(store.isFavorite('c1'), isTrue, reason: 'shown immediately');
      expect(await pending, isNull);
      await pumpEventQueue();
      expect(store.favorites, {'c1'});
      expect(users.profiles['me']!.favorites, {'c1'});

      await store.toggle('c1');
      await pumpEventQueue();
      expect(store.isFavorite('c1'), isFalse);
    });

    test('rolls back when the write fails', () async {
      final users = _FailingUsers()
        ..put(const UserProfile(uid: 'me', name: 'Me', username: 'me'));
      final store = FavoritesStore(users)..attach('me');
      await pumpEventQueue();

      final failure = await store.toggle('c1');
      expect(failure, isA<AppFailure>());
      expect(store.isFavorite('c1'), isFalse);
    });
  });

  group('CapsuleCountdown', () {
    final now = DateTime(2025, 1, 1, 12);

    test('opened or without a date', () {
      expect(CapsuleCountdown.format(null, now), 'Capsule is opened!');
      expect(
        CapsuleCountdown.format(now.subtract(const Duration(days: 1)), now),
        'Capsule is opened!',
      );
    });

    test('days and seconds, years without seconds', () {
      expect(
        CapsuleCountdown.format(
          now.add(const Duration(days: 2, hours: 3, minutes: 4, seconds: 5)),
          now,
        ),
        '2d 3h 4m 5s',
      );
      expect(
        CapsuleCountdown.format(now.add(const Duration(days: 400)), now),
        '1y 35d 0h 0m',
      );
    });
  });

  testWidgets(
    'a capsule without location, image or dates renders on a 320 dp phone '
    '(BUG-060, BUG-064, BUG-065)',
    (tester) async {
      tester.view
        ..physicalSize = const Size(320, 640)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider(create: (_) => GeocodingService()),
            ChangeNotifierProvider(create: (_) => CurrentLocation()),
          ],
          child: testApp(
            home: Scaffold(
              body: CapsuleListTile(
                capsule: _c(
                  'x',
                  title: 'A very long capsule title that does not fit',
                  privacy: CapsulePrivacy.friends,
                ),
                isFavorite: false,
                onFavoriteTap: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Capsule is opened!'), findsOneWidget);
      expect(find.text('Friends visibility'), findsOneWidget);
      expect(find.text('Distance unknown'), findsOneWidget);
      expect(find.text('No location'), findsOneWidget);
      expect(find.byIcon(Icons.lock_clock), findsOneWidget);
    },
  );

  testWidgets('a capsule shows its countdown, distance and date', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => GeocodingService()),
          ChangeNotifierProvider(
            create: (_) => CurrentLocation()..update(const GeoPosition(0, 0)),
          ),
        ],
        child: testApp(
          home: Scaffold(
            body: CapsuleListTile(
              capsule: _c(
                'x',
                title: 'Trip',
                privacy: CapsulePrivacy.private,
                location: const GeoPosition(0, 0.1),
                createdAt: DateTime(2026, 1, 5),
                openAt: DateTime.now().add(
                  const Duration(days: 3, hours: 1, minutes: 30),
                ),
              ),
              isFavorite: true,
              onFavoriteTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining(RegExp(r'^3d 1h \d+m \d+s$')), findsOneWidget);
    expect(find.text('Private visibility'), findsOneWidget);
    expect(find.text('11.1 km from you'), findsOneWidget);
    expect(find.text('05.01.2026'), findsOneWidget);
    // No geocoder in tests: the place pill says so instead of staying empty.
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.text('Unknown location'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Remove from favorites',
      ),
      findsOneWidget,
    );
    // Stop the countdown's timer before the test ends.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the selection bar counts the capsules', (tester) async {
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: SelectionActionBar(count: 2, onCancel: () {}, onDelete: () {}),
        ),
      ),
    );

    expect(find.text('2 selected'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete (2)'), findsOneWidget);
  });

  testWidgets('empty: what a capsule is and a way to make one; no match: '
      'a way back to all of them', (tester) async {
    final repo = FakeCapsuleRepository();
    final store = OwnCapsulesStore(repo)..attach('me');
    final favorites = FavoritesStore(FakeUserRepository())..attach('me');
    addTearDown(() {
      store
        ..detach()
        ..dispose();
      favorites
        ..detach()
        ..dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: store),
          ChangeNotifierProvider.value(value: favorites),
          ChangeNotifierProvider(create: (_) => CurrentLocation()),
          ChangeNotifierProvider(create: (_) => MapFocus()),
          Provider(create: (_) => GeocodingService()),
        ],
        child: testApp(home: const Scaffold(body: HistoryPage())),
      ),
    );
    await tester.pump();
    expect(find.text('No capsules yet'), findsOneWidget);
    expect(find.text('Create a capsule'), findsOneWidget);

    repo.emitOwn([_c('a', title: 'Beach')]);
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('No capsules match your search'), findsOneWidget);
    await tester.tap(find.text('Reset').last);
    await tester.pump();
    expect(find.text('Beach'), findsOneWidget);
    // Stop the tile's countdown before the test ends.
    await tester.pumpWidget(const SizedBox());
  });
}

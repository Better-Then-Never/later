// The world view (B7): the summary as read, the place from the geocoder at
// creation, the passport page and its row on the profile.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:later/data/firebase/firestore_mappers.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/models/world.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/services/country_names.dart';
import 'package:later/data/services/geocoding_service.dart';
import 'package:later/data/services/location_service.dart';
import 'package:later/features/capsules/creation/capsule_creation_controller.dart';
import 'package:later/features/map/current_location.dart';
import 'package:later/features/world/world_page.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

class _NoLocation implements LocationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GeocodingService _geocoder(Placemark mark, {List<String>? asked}) =>
    GeocodingService(
      placemarks: (lat, lng) async {
        asked?.add('$lat,$lng');
        return [mark];
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the summary as read: tolerant, first visit first', () {
    final world = FirestoreMappers.world({
      'countries': {
        'PL': {
          'capsules': 3,
          'cities': {'Warszawa': 2, 'Kraków': 1, 'bad': 'x'},
          'first': Timestamp.fromDate(DateTime(2026, 5)),
        },
        'DE': {
          'capsules': 1,
          'cities': {'Berlin': 1},
          'first': Timestamp.fromDate(DateTime(2025, 1)),
        },
        'xx': {'capsules': 9},
      },
    });
    expect([for (final c in world.countries) c.code], ['DE', 'PL']);
    expect(world.cityCount, 3);
    expect(world.countries.last.towns, ['Warszawa', 'Kraków']);
    expect(FirestoreMappers.world(null).isEmpty, isTrue);
    expect(CountryNames.flag('PL'), '🇵🇱');
  });

  test('the geocoder gives the town and the country code', () async {
    final asked = <String>[];
    final geo = _geocoder(
      const Placemark(locality: ' Kraków ', isoCountryCode: 'pl'),
      asked: asked,
    );
    final place = await geo.place(const GeoPosition(50.06, 19.94));
    expect(place?.name, 'Kraków');
    expect(place?.countryCode, 'PL');
    expect(await geo.placeName(const GeoPosition(50.06, 19.94)), 'Kraków');
    expect(asked, hasLength(1), reason: 'cached');
    final odd = _geocoder(const Placemark(isoCountryCode: 'POL'));
    expect(await odd.place(const GeoPosition(1, 2)), isNull);
  });

  test('a new capsule carries its town and country', () async {
    final repo = FakeCapsuleRepository();
    final c = CapsuleCreationController(
      ownerId: 'me',
      imagePath: 'does/not/exist.jpg',
      capsules: repo,
      location: _NoLocation(),
      currentLocation: CurrentLocation()..update(const GeoPosition(52, 21)),
      geocoding: _geocoder(
        const Placemark(locality: 'Warszawa', isoCountryCode: 'PL'),
      ),
    );
    expect(await c.save(), isNull);
    expect(repo.created.single.placeName, 'Warszawa');
    expect(repo.created.single.countryCode, 'PL');
    expect(
      FirestoreMappers.newCapsule(
        repo.created.single,
        imageUrl: 'https://x',
      )['countryCode'],
      'PL',
    );
    c.dispose();
  });

  Future<void> pumpPage(WidgetTester tester, WorldSummary world) async {
    final social = FakeSocialRepository()..worlds['me'] = world;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SocialRepository>.value(value: social),
          Provider(create: (_) => CountryNames()),
        ],
        child: testApp(home: const WorldPage(uid: 'me')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the passport: totals and a stamp per country', (tester) async {
    await pumpPage(
      tester,
      WorldSummary(
        countries: [
          CountryVisit(
            code: 'PL',
            capsules: 3,
            cities: const {'Warszawa': 2, 'Kraków': 1, 'Gdańsk': 1},
            first: DateTime(2026, 5),
          ),
          const CountryVisit(code: 'DE', capsules: 1),
        ],
      ),
    );
    expect(find.text('Passport'), findsOneWidget);
    expect(find.text('countries'), findsOneWidget);
    expect(find.text('towns'), findsOneWidget);
    expect(find.byType(Stamp), findsNWidgets(2));
    // Off Android the name is the code.
    expect(find.text('PL'), findsOneWidget);
    expect(find.text('3 capsules'), findsOneWidget);
    expect(find.text('Warszawa, Gdańsk +1'), findsOneWidget);
    expect(find.text('First: May 2026'), findsOneWidget);
  });

  testWidgets('an empty passport says how to get a stamp', (tester) async {
    await pumpPage(tester, WorldSummary.empty);
    expect(find.byType(Stamp), findsNothing);
    expect(find.textContaining('gets a stamp here'), findsOneWidget);
  });

  testWidgets('a long name at a large text size fits its stamp', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: Center(
            child: SizedBox(
              width: 164,
              height: 182,
              child: Stamp(
                visit: CountryVisit(
                  code: 'US',
                  capsules: 12,
                  cities: const {'New York': 9, 'Los Angeles': 3},
                  first: DateTime(2026, 1),
                ),
                name: 'Соединенные Штаты Америки',
                index: 0,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull, reason: 'no overflow');
  });

  test('the stats carry the totals for the profile row', () {
    final stats = FirestoreMappers.userStats({'countries': 2, 'cities': 5});
    expect(stats.countries, 2);
    expect(stats.cities, 5);
    expect(const UserStats().countries, 0);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/world.dart';
import 'package:later/features/stamps/new_stamp_moment.dart';
import 'package:later/features/stamps/stamps.dart';

import '../helpers/capsule_host.dart';
import '../helpers/test_app.dart';

const _world = WorldSummary(
  countries: [
    CountryVisit(code: 'PL', capsules: 9, cities: {'Warszawa': 7, 'Kraków': 2}),
    CountryVisit(code: 'DE', capsules: 1, cities: {'Berlin': 1}),
  ],
);

void main() {
  group('a stamp per town (E1, E2)', () {
    test('the town as the functions keep it', () {
      expect(
        Stamps.townKey(' St. Petersburg / Old  Town '),
        'St Petersburg Old Town',
      );
      expect(Stamps.townKey('__x__'), isNull);
      expect(Stamps.townKey('  '), isNull);
      expect(Stamps.townKey(null), isNull);
      expect(Stamps.townKey('a' * 90)!.length, 80);
    });

    test('the first capsule in a town earns it, numbered', () {
      final stamp = Stamps.newStamp(
        _world,
        countryCode: 'PL',
        placeName: 'Gdańsk',
      );
      expect(stamp?.town, 'Gdańsk');
      expect(stamp?.number, 4);
      expect(stamp?.country, 'PL');
    });

    test('not again in a town that has one, nor without a town', () {
      expect(
        Stamps.newStamp(_world, countryCode: 'PL', placeName: 'Warszawa'),
        isNull,
      );
      expect(
        Stamps.newStamp(_world, countryCode: 'PL', placeName: null),
        isNull,
      );
      expect(
        Stamps.newStamp(_world, countryCode: null, placeName: 'Gdańsk'),
        isNull,
      );
      // The same name in another country is another town.
      expect(
        Stamps.newStamp(_world, countryCode: 'US', placeName: 'Warszawa'),
        isNotNull,
      );
    });

    test('ordinals in each language', () {
      expect(Stamps.ordinal(22, 'de'), '22.');
      expect(Stamps.ordinal(22, 'pl'), '22.');
      expect(Stamps.ordinal(22, 'ru'), '22-й');
      expect(Stamps.ordinal(22, 'es'), '22.ª');
      expect(Stamps.ordinal(22, 'en_GB'), '22nd');
    });

    test('English ordinals', () {
      expect(
        [
          1,
          2,
          3,
          4,
          11,
          12,
          13,
          21,
          22,
          23,
          101,
          111,
        ].map(Stamps.englishOrdinal),
        [
          '1st',
          '2nd',
          '3rd',
          '4th',
          '11th',
          '12th',
          '13th',
          '21st',
          '22nd',
          '23rd',
          '101st',
          '111th',
        ],
      );
    });
  });

  testWidgets('the new stamp: the page, the words, it lands, then closes', (
    tester,
  ) async {
    await tester.pumpWidget(
      capsuleHost(
        child: testApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => NewStampMoment.show(
                context,
                town: 'Gdańsk',
                number: 22,
                color: CapsuleColor.orange,
                countryCode: 'PL',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('New stamp'), findsOneWidget);
    expect(find.text('Gdańsk, your 22nd town'), findsOneWidget);
    expect(find.text('GDAŃSK'), findsOneWidget);
    expect(find.text('Open passport'), findsOneWidget);
    // Page 2 holds stamps 1-7, page 3 8-14, page 4 15-21: the 22nd is on 5.
    expect(find.text('5'), findsOneWidget);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('New stamp'), findsNothing);
  });
}

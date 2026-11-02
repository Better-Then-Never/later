// The Passport's data (Profile v4): towns as stamps, the pages they fill,
// what two people share, the year, a name as a passport prints it.
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/world.dart';
import 'package:later/features/passport/passport_data.dart';

final _world = WorldSummary(
  countries: [
    CountryVisit(
      code: 'PL',
      capsules: 9,
      cities: const {'Kraków': 2, 'Warszawa': 6, 'Gdańsk': 1},
      first: DateTime(2025, 3, 12),
      last: DateTime(2026, 9, 1),
    ),
    CountryVisit(
      code: 'DE',
      capsules: 3,
      cities: const {'Berlin': 3},
      first: DateTime(2025, 8, 8),
      last: DateTime(2025, 8, 20),
    ),
    CountryVisit(
      code: 'NO',
      capsules: 2,
      cities: const {'Stavanger': 1, 'Bergen': 1},
      first: DateTime(2026, 6, 14),
      last: DateTime(2026, 7, 2),
    ),
  ],
);

WorldSummary _towns(int n) => WorldSummary(
  countries: [
    CountryVisit(
      code: 'PL',
      capsules: n,
      cities: {for (var i = 0; i < n; i++) 'Town $i': 1},
    ),
  ],
);

void main() {
  group('a name as a passport prints it', () {
    test('the last word is the surname, the rest given names', () {
      final two = PassportData.splitName('Alice Walker');
      expect(two.surname, 'Walker');
      expect(two.given, 'Alice');
      expect(two.hasSurname, isTrue);
      final three = PassportData.splitName('  Anna  Maria   Nowak ');
      expect(three.surname, 'Nowak');
      expect(three.given, 'Anna Maria');
    });

    test('one word (or none) is just a name', () {
      final one = PassportData.splitName(' Bob ');
      expect(one.hasSurname, isFalse);
      expect(one.given, 'Bob');
      expect(PassportData.splitName('').given, '');
      expect(PassportData.splitName('   ').hasSurname, isFalse);
    });

    test('the machine-readable line', () {
      expect(
        PassportData.mrz(['Walker', 'Alice Mary'], length: 24),
        'WALKER<<ALICE<MARY<<<<<<',
      );
      expect(PassportData.mrz(['', 'Bob'], length: 5), 'BOB<<');
      expect(PassportData.mrz(['abcdefgh'], length: 4), 'ABCD');
    });
  });

  group('towns', () {
    test('countries in order, most capsules first, a date only when sure', () {
      final towns = PassportData.towns(_world);
      expect(towns.map((t) => t.town), [
        'Warszawa',
        'Kraków',
        'Gdańsk',
        'Berlin',
        'Bergen',
        'Stavanger',
      ]);
      expect(towns.first.capsules, 6);
      expect(towns.first.countryCode, 'PL');
      // Poland has three towns: its first visit is not Warszawa's.
      expect(towns.first.first, isNull);
      expect(towns.first.countryFirst, DateTime(2025, 3, 12));
      // Berlin is Germany's only town: Germany's first visit is Berlin's.
      expect(towns[3].first, DateTime(2025, 8, 8));
    });

    test('the first stamp is the earliest first visit', () {
      expect(PassportData.since(_world), DateTime(2025, 3, 12));
      expect(PassportData.since(WorldSummary.empty), isNull);
    });
  });

  group('pages', () {
    test('items cut into pages, the last one short', () {
      final pages = PassportData.pages(List.generate(16, (i) => i), 7);
      expect(pages.map((p) => p.length), [7, 7, 2]);
      expect(pages.last, [14, 15]);
      expect(PassportData.pages(<int>[], 7), isEmpty);
    });

    test('the book: cover, photo, stamps by seven, visas by three', () {
      final book = PassportData.book(_towns(16));
      expect(book, const [
        PassportLeaf(PassportLeafKind.cover),
        PassportLeaf(PassportLeafKind.photo, number: 1),
        PassportLeaf(PassportLeafKind.stamps, number: 2, start: 0, count: 7),
        PassportLeaf(PassportLeafKind.stamps, number: 3, start: 7, count: 7),
        PassportLeaf(PassportLeafKind.stamps, number: 4, start: 14, count: 2),
        PassportLeaf(PassportLeafKind.visas, number: 5, start: 0, count: 1),
      ]);
      final full = PassportData.book(_world, together: true, year: true);
      expect(full.map((l) => l.kind), [
        PassportLeafKind.cover,
        PassportLeafKind.together,
        PassportLeafKind.photo,
        PassportLeafKind.stamps,
        PassportLeafKind.visas,
        PassportLeafKind.year,
      ]);
      expect(full.last.number, 4);
    });

    test('an empty book has the empty stamps page', () {
      expect(PassportData.book(WorldSummary.empty).map((l) => l.kind), [
        PassportLeafKind.cover,
        PassportLeafKind.photo,
        PassportLeafKind.empty,
      ]);
    });

    test('where the book opens', () {
      final world = _towns(16);
      final towns = PassportData.towns(world);
      final book = PassportData.book(world);
      expect(PassportData.openAt(book, towns), 0, reason: 'the cover');
      expect(PassportData.openAt(book, towns, focusTown: 'Town 2'), 3);
      expect(PassportData.openAt(book, towns, focusTown: 'Town 0'), 2);
      // Not in the summary yet: the last stamps page.
      expect(PassportData.openAt(book, towns, focusTown: 'Elsewhere'), 4);
      final empty = PassportData.book(WorldSummary.empty);
      expect(PassportData.openAt(empty, const [], focusTown: 'Gdańsk'), 2);
      final friend = PassportData.book(world, together: true);
      expect(PassportData.openAt(friend, towns), 1, reason: 'You and Bob');
    });

    test('the new-stamp moment counts the same seven a page', () {
      // Its page number: 2 + (n - 1) ~/ 7; the book's stamps start at 2.
      final book = PassportData.book(_towns(22));
      final stamps = book.where((l) => l.kind == PassportLeafKind.stamps);
      expect(stamps.last.number, 2 + (22 - 1) ~/ 7);
    });
  });

  group('you and a friend', () {
    const bob = WorldSummary(
      countries: [
        CountryVisit(
          code: 'PL',
          capsules: 4,
          cities: {'Warszawa': 3, 'Zakopane': 1},
        ),
        CountryVisit(code: 'IS', capsules: 1, cities: {'Reykjavík': 1}),
        CountryVisit(code: 'NO', capsules: 1, cities: {'Oslo': 1}),
      ],
    );

    test('both, only mine, only theirs', () {
      final both = PassportData.compare(_world, bob);
      expect(both.countries, ['PL', 'NO']);
      expect(both.towns.map((t) => t.town), ['Warszawa']);
      expect(both.towns.single.capsules, 3, reason: 'their stamp');
      expect(both.onlyMine, ['DE']);
      expect(both.onlyTheirs, ['IS']);
    });

    test('nothing in common', () {
      final none = PassportData.compare(_world, WorldSummary.empty);
      expect(none.countries, isEmpty);
      expect(none.towns, isEmpty);
      expect(none.onlyMine, ['PL', 'DE', 'NO']);
      expect(none.onlyTheirs, isEmpty);
    });
  });

  group('the year', () {
    test('countries visited in it, at their latest visit; the new ones', () {
      final year = PassportData.year(_world, 2026)!;
      expect(year.countryCount, 2);
      expect(
        [for (final v in year.visits) '${v.code}${v.month}'],
        ['NO7', 'PL9'],
      );
      expect(year.entered, ['NO']);
      expect(year.visits.first.isNew, isTrue);
      expect(year.visits.last.isNew, isFalse);
    });

    test('a year without a capsule has no page', () {
      expect(PassportData.year(_world, 2024), isNull);
      final y2025 = PassportData.year(_world, 2025)!;
      expect(y2025.visits.single.code, 'DE');
      expect(y2025.entered, ['DE']);
    });

    test('a country without a last visit counts by its first', () {
      final world = WorldSummary(
        countries: [CountryVisit(code: 'PL', first: DateTime(2026, 2, 3))],
      );
      expect(PassportData.year(world, 2026)!.visits.single.month, 2);
    });
  });
}

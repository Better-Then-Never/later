// The Passport booklet (Profile v4, Figma page 8 and page 14): the cover,
// the photo page, the stamps and their sheet, the visas, the year, an empty
// passport, and You and a friend.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/models/world.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/services/country_names.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:later/features/passport/passport_cover.dart';
import 'package:later/features/passport/passport_data.dart';
import 'package:later/features/passport/passport_sheets.dart';
import 'package:later/features/passport/passport_visas_page.dart';
import 'package:later/features/passport/passport_year_page.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:later/features/world/world_page.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

final _world = WorldSummary(
  countries: [
    CountryVisit(
      code: 'PL',
      capsules: 9,
      cities: const {'Warszawa': 6, 'Kraków': 2, 'Gdańsk': 1},
      first: DateTime(2025, 3, 12),
      last: DateTime(2025, 9, 1),
    ),
    CountryVisit(
      code: 'DE',
      capsules: 3,
      cities: const {'Berlin': 3},
      first: DateTime(2025, 8, 8),
      last: DateTime(2025, 8, 20),
    ),
  ],
);

const _alice = UserProfile(
  uid: 'me',
  name: 'Alice Walker',
  username: 'alice',
  about: 'Collecting small moments',
  homeTown: 'Warszawa',
  stats: UserStats(capsules: 102),
);

const _bob = UserProfile(uid: 'bob', name: 'Bob Stone', username: 'bob');

void main() {
  late FakeSocialRepository social;
  late FakeUserRepository users;

  setUp(() {
    social = FakeSocialRepository();
    users = FakeUserRepository()
      ..put(_alice)
      ..put(_bob);
  });

  Widget providers(Widget child, {double textScale = 1}) => MultiProvider(
    providers: [
      Provider<SocialRepository>.value(value: social),
      Provider(create: (_) => CountryNames()),
      ChangeNotifierProvider(create: (_) => UserDirectory(users)),
      ChangeNotifierProvider(
        create: (_) => ProfileImageCache(FakeImageStorageRepository()),
      ),
    ],
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(360, 800),
        textScaler: TextScaler.linear(textScale),
      ),
      child: child,
    ),
  );

  Future<void> pumpPassport(
    WidgetTester tester, {
    String uid = 'me',
    String? viewer,
    String? focusTown,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      providers(
        testApp(
          home: WorldPage(uid: uid, viewerUid: viewer, focusTown: focusTown),
        ),
        textScale: textScale,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the cover: foil words, whose places, the totals', (
    tester,
  ) async {
    social.worlds['me'] = _world;
    await pumpPassport(tester);
    expect(find.text('Passport'), findsOneWidget, reason: 'the header');
    expect(find.byType(PassportCover), findsOneWidget);
    expect(find.text('LATER'), findsOneWidget);
    expect(find.text('PASSPORT'), findsOneWidget);
    expect(find.text('Places where you left a capsule'), findsOneWidget);
    expect(
      find.text('2 countries · 4 towns · stamps since 12 Mar 2025'),
      findsOneWidget,
    );
    expect(find.text('Tap to open'), findsOneWidget);
    expect(find.bySemanticsLabel('Share this page'), findsOneWidget);
  });

  testWidgets('a tap opens the photo page: fields, numbers, words, MRZ', (
    tester,
  ) async {
    social.worlds['me'] = _world;
    await pumpPassport(tester);
    await tester.tap(find.byType(PassportCover));
    await tester.pumpAndSettle();
    expect(find.text('SURNAME'), findsOneWidget);
    expect(find.text('WALKER'), findsOneWidget);
    expect(find.text('GIVEN NAMES'), findsOneWidget);
    expect(find.text('ALICE'), findsOneWidget);
    expect(find.text('@alice'), findsOneWidget);
    expect(find.text('HOME TOWN'), findsOneWidget);
    expect(find.text('WARSZAWA'), findsOneWidget);
    expect(find.text('102'), findsOneWidget);
    expect(find.text('CAPSULES'), findsOneWidget);
    expect(find.text('COUNTRIES'), findsOneWidget);
    expect(find.text('TOWNS'), findsOneWidget);
    expect(find.text('“Collecting small moments”'), findsOneWidget);
    expect(find.text('FIRST ENTRY'), findsOneWidget);
    expect(find.textContaining('P<LTRWALKER<<ALICE<'), findsOneWidget);
    expect(find.text('Swipe to turn the page'), findsOneWidget);
    // No account date in the app: no "holder since".
    expect(find.textContaining('SINCE'), findsNothing);
  });

  testWidgets('a one-word name is just NAME; no home town, no words', (
    tester,
  ) async {
    users.put(const UserProfile(uid: 'me', name: 'Cher', username: 'cher'));
    social.worlds['me'] = _world;
    await pumpPassport(tester);
    await tester.tap(find.byType(PassportCover));
    await tester.pumpAndSettle();
    expect(find.text('NAME'), findsOneWidget);
    expect(find.text('CHER'), findsOneWidget);
    expect(find.text('SURNAME'), findsNothing);
    expect(find.text('HOME TOWN'), findsNothing);
    expect(find.textContaining('“'), findsNothing);
  });

  testWidgets('a new stamp opens its page; a stamp opens its sheet', (
    tester,
  ) async {
    social.worlds['me'] = _world;
    await pumpPassport(tester, focusTown: 'Kraków');
    expect(find.text('STAMPS · PIECZĘCIE'), findsOneWidget);
    expect(find.text('KRAKÓW'), findsOneWidget);
    // Berlin is Germany's only town: its day is known.
    expect(find.text('8 AUG 2025'), findsOneWidget);
    // Kraków's day is not: its capsules instead.
    expect(find.text('2 CAPSULES'), findsOneWidget);
    expect(find.text('Tap a stamp to see more'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Kraków')));
    await tester.pumpAndSettle();
    expect(find.byType(PassportStampSheet), findsOneWidget);
    expect(find.text('Kraków'), findsOneWidget);
    expect(find.text('First capsule in PL on 12 Mar 2025'), findsOneWidget);
    expect(find.text('2 capsules'), findsOneWidget);
    // No position per town: no map button.
    expect(find.text('Show on the map'), findsNothing);
  });

  testWidgets('a lone town\'s sheet knows its first day', (tester) async {
    social.worlds['me'] = _world;
    await pumpPassport(tester, focusTown: 'Berlin');
    await tester.tap(find.bySemanticsLabel(RegExp('^Berlin')));
    await tester.pumpAndSettle();
    expect(find.text('First capsule here on 8 Aug 2025'), findsOneWidget);
    expect(find.text('3 capsules'), findsOneWidget);
  });

  testWidgets('the empty passport: the first stamp to come', (tester) async {
    await pumpPassport(tester, focusTown: 'Gdańsk');
    expect(find.text('Your first stamp'), findsOneWidget);
    expect(
      find.text('Leave a capsule somewhere and its town is stamped here.'),
      findsOneWidget,
    );
    expect(find.text('Make a capsule'), findsOneWidget);
  });

  testWidgets('the empty cover has no first day', (tester) async {
    await pumpPassport(tester);
    expect(find.text('0 countries · 0 towns'), findsOneWidget);
  });

  testWidgets('a friend\'s passport opens at You and Bob', (tester) async {
    social.worlds['me'] = _world;
    social.worlds['bob'] = const WorldSummary(
      countries: [
        CountryVisit(
          code: 'PL',
          capsules: 4,
          cities: {'Warszawa': 3, 'Zakopane': 1},
        ),
        CountryVisit(code: 'IS', capsules: 1, cities: {'Reykjavík': 1}),
      ],
    );
    await pumpPassport(tester, uid: 'bob', viewer: 'me');
    expect(find.text("Bob's Passport"), findsOneWidget);
    expect(find.text('YOU AND BOB'), findsOneWidget);
    expect(find.text('Both of you: 1 country, 1 town'), findsOneWidget);
    expect(find.text('BOTH'), findsOneWidget);
    expect(find.text('WARSZAWA'), findsOneWidget, reason: 'the shared stamp');
    expect(find.text('ONLY BOB'), findsOneWidget);
    expect(find.text('IS'), findsOneWidget);
    expect(find.text('ONLY YOU'), findsOneWidget);
    expect(find.text('DE'), findsOneWidget);
    expect(find.text("Swipe for Bob's own pages"), findsOneWidget);
    // Back to Bob's cover.
    await tester.drag(find.byType(PageView), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Places where Bob left a capsule'), findsOneWidget);
  });

  testWidgets('nothing in common with a friend', (tester) async {
    social.worlds['bob'] = const WorldSummary(
      countries: [CountryVisit(code: 'IS', capsules: 1)],
    );
    await pumpPassport(tester, uid: 'bob', viewer: 'me');
    expect(find.text('No towns in common yet'), findsOneWidget);
    expect(find.text('None yet'), findsOneWidget, reason: 'only you');
  });

  testWidgets('a large text size still fits the photo page', (tester) async {
    social.worlds['me'] = _world;
    users.put(
      const UserProfile(
        uid: 'me',
        name: 'Maria Magdalena Konstantynopolitańczykowska',
        username: 'maria_magdalena_long',
        about:
            'A very long about me that goes on and on to fill the hundred '
            'characters it may have here.',
        homeTown: 'Gorzów Wielkopolski',
      ),
    );
    await pumpPassport(tester, textScale: 1.6);
    await tester.tap(find.byType(PassportCover));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'no overflow');
    expect(find.text('KONSTANTYNOPOLITAŃCZYKOWSKA'), findsOneWidget);
  });

  testWidgets('visas: a band, the code, first entry, towns and capsules', (
    tester,
  ) async {
    await tester.pumpWidget(
      providers(
        testApp(
          home: Scaffold(
            body: SizedBox(
              width: 328,
              height: 520,
              child: PassportVisasPage(
                countries: _world.countries,
                first: 0,
                number: 3,
                countryName: (code) => code == 'PL' ? 'Poland' : 'Germany',
                onTap: (country, index) => PassportVisaSheet.show(
                  tester.element(find.byType(PassportVisasPage)),
                  country: country,
                  index: index,
                  name: country.code == 'PL' ? 'Poland' : 'Germany',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('VISAS'), findsOneWidget);
    expect(find.text('VISA · PL'), findsOneWidget);
    expect(find.text('POLAND'), findsOneWidget);
    expect(find.text('GERMANY'), findsOneWidget);
    expect(find.text('FIRST ENTRY'), findsNWidgets(2));
    expect(find.text('12 MAR 2025'), findsOneWidget);
    expect(find.text('3 towns · 9 capsules'), findsOneWidget);
    expect(
      find.textContaining('V<PL<<WARSZAWA<KRAKÓW<GDAŃSK<'),
      findsOneWidget,
    );
    expect(find.text('3'), findsOneWidget, reason: 'the page number');
    await tester.tap(find.bySemanticsLabel(RegExp('^Poland')));
    await tester.pumpAndSettle();
    expect(find.text('Poland'), findsOneWidget);
    expect(find.text('First capsule in Poland on 12 Mar 2025'), findsOneWidget);
    expect(find.text('Warszawa'), findsOneWidget);
    expect(find.text('6 capsules'), findsOneWidget);
  });

  testWidgets('your year: the year, its countries on their months', (
    tester,
  ) async {
    final world = WorldSummary(
      countries: [
        ..._world.countries,
        CountryVisit(
          code: 'NO',
          capsules: 6,
          cities: const {'Stavanger': 4, 'Bergen': 2},
          first: DateTime(2026, 6, 14),
          last: DateTime(2026, 6, 30),
        ),
      ],
    );
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: SizedBox(
            width: 328,
            height: 520,
            child: PassportYearPage(
              year: PassportData.year(world, 2026)!,
              number: 5,
              countryName: (code) => code == 'NO' ? 'Norway' : code,
              about: 'Collecting small moments',
            ),
          ),
        ),
      ),
    );
    expect(find.text('YOUR YEAR'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('NEW THIS YEAR'), findsOneWidget);
    expect(find.text('Norway'), findsOneWidget);
    expect(find.text('NO'), findsOneWidget, reason: 'on June');
    expect(find.text('J'), findsNWidgets(3));
    expect(find.text('“Collecting small moments”'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the year page is last in your own passport only', (
    tester,
  ) async {
    final now = DateTime.now();
    social.worlds['me'] = WorldSummary(
      countries: [
        CountryVisit(
          code: 'PL',
          capsules: 1,
          cities: const {'Warszawa': 1},
          first: now,
          last: now,
        ),
      ],
    );
    await pumpPassport(tester);
    // Cover, photo, stamps, visas, year.
    for (var i = 0; i < 4; i++) {
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
    }
    expect(find.text('YOUR YEAR'), findsOneWidget);
    expect(find.text('${now.year}'), findsOneWidget);
  });
}

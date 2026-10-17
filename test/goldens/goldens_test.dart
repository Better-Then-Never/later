// Golden images of a few shared widgets, rendered with the app font, so
// unintended visual changes show up as test failures.
//
// Update after an intended change: flutter test --update-goldens test/goldens
// Goldens depend on the host's font rasteriser: they were generated on
// Windows; on other platforms run with --update-goldens first or skip the
// `golden` tag (flutter test --exclude-tags golden).
@Tags(['golden'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/theme/app_text_styles.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/services/geocoding_service.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:later/features/friends/widgets/requests/friend_requests_received_row.dart';
import 'package:later/features/history/widgets/capsule_list_tile.dart';
import 'package:later/features/map/current_location.dart';
import 'package:later/features/profile/widgets/image_options_sheet.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/features/settings/device_settings_store.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
      Future.value(ByteData.sublistView(File(path).readAsBytesSync())),
    );
  }
  await loader.load();
}

/// The app font, plus Material Icons from the Flutter SDK (tests render
/// icons as boxes otherwise).
Future<void> _loadFonts() async {
  await _loadFont(kAppFontFamily, [
    'assets/fonts/inria_sans/InriaSans-Regular.ttf',
    'assets/fonts/inria_sans/InriaSans-Bold.ttf',
  ]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final icons = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
  );
  if (flutterRoot != null && icons.existsSync()) {
    await _loadFont('MaterialIcons', [icons.path]);
  }
}

/// Decodes every asset image on screen so it appears in the golden.
Future<void> _precacheImages(WidgetTester tester) async {
  // Picture lookups (fake, immediate) finish first: avatars then show their
  // final image, not the skeleton of a pending lookup.
  await tester.pump();
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pump();
}

/// Fixed place name instead of the platform geocoder.
class _FixedGeocoding extends GeocodingService {
  @override
  Future<String?> placeName(GeoPosition position) async => 'Mountain View';
}

Widget _app(Widget child) => MultiProvider(
  providers: [
    Provider<GeocodingService>(create: (_) => _FixedGeocoding()),
    ChangeNotifierProvider(
      create: (_) =>
          CurrentLocation()..update(const GeoPosition(37.42, -122.08)),
    ),
    ChangeNotifierProvider(
      create: (_) => ProfileImageCache(FakeImageStorageRepository()),
    ),
    ChangeNotifierProvider(
      create: (_) => DeviceSettingsStore(PreferencesStore()),
    ),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: ThemeData(fontFamily: kAppFontFamily),
    home: Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      // Laid out like in the app's lists: full width, natural height.
      body: ListView(
        padding: const EdgeInsets.only(top: 40),
        children: [child],
      ),
    ),
  ),
);

void main() {
  setUpAll(_loadFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> phone(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
  }

  testWidgets('capsule list tile', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      _app(
        CapsuleListTile(
          capsule: Capsule(
            id: 'c1',
            ownerId: 'me',
            title: 'Beach day',
            privacy: CapsulePrivacy.public,
            color: CapsuleColor.yellow,
            location: const GeoPosition(37.35, -121.95),
            createdAt: DateTime(2026, 10, 15),
          ),
          isFavorite: true,
          onFavoriteTap: () {},
        ),
      ),
    );
    await _precacheImages(tester);
    await expectLater(
      find.byType(CapsuleListTile),
      matchesGoldenFile('capsule_list_tile.png'),
    );
  });

  testWidgets('received friend request row', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      _app(
        Padding(
          padding: const EdgeInsets.all(15),
          child: FriendRequestsReceivedRow(
            uid: 'dave',
            name: 'Dave Miller',
            username: 'davem',
            screenWidth: 1080 / 2.625,
            onTap: () {},
            onAccept: () {},
            onReject: () {},
          ),
        ),
      ),
    );
    await _precacheImages(tester);
    await expectLater(
      find.byType(FriendRequestsReceivedRow),
      matchesGoldenFile('friend_request_received_row.png'),
    );
  });

  testWidgets('image options sheet', (tester) async {
    await phone(tester);
    await tester.pumpWidget(
      _app(
        const ImageOptionsSheet(
          title: 'Profile picture',
          deleteLabel: 'Delete profile icon',
        ),
      ),
    );
    await _precacheImages(tester);
    await expectLater(
      find.byType(ImageOptionsSheet),
      matchesGoldenFile('image_options_sheet.png'),
    );
  });
}

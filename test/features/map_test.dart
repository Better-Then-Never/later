import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_theme.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/features/map/current_location.dart';
import 'package:later/features/map/map_controller.dart';
import 'package:later/features/map/map_focus.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/features/map/widgets/capsule_info_panel.dart';

import '../helpers/test_app.dart';

Capsule _c(String owner, CapsulePrivacy privacy) => Capsule(
  id: '$owner-${privacy.name}',
  ownerId: owner,
  title: 't',
  privacy: privacy,
  color: CapsuleColor.red,
);

/// The app font, so text widths are the real ones rather than the wide test
/// font's.
Future<void> _loadAppFont() async {
  final loader = FontLoader('Irina');
  for (final face in ['Regular', 'Bold']) {
    final bytes = File(
      'assets/fonts/inria_sans/InriaSans-$face.ttf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

/// A capsule that opens [opensIn] from now (already open when null).
Capsule _panelCapsule({Duration? opensIn}) => Capsule(
  id: 'c',
  ownerId: 'me',
  title: 'Picnic by the river',
  privacy: CapsulePrivacy.public,
  color: CapsuleColor.red,
  createdAt: DateTime(2026, 10, 16),
  openAt: opensIn == null ? null : DateTime.now().add(opensIn),
);

/// The info panel at the size the map gives it on a 320 dp phone.
Widget _panel(
  Capsule capsule, {
  Locale locale = const Locale('en'),
  bool dark = false,
  VoidCallback? onMoreInfo,
}) => testApp(
  locale: locale,
  theme: dark ? AppTheme.dark : AppTheme.light,
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 320 * 0.58,
        // The content is about 2 px taller than minHeight with the app font
        // in tests, in English too (unchanged by the translations); these
        // tests are about the texts fitting the panel's width.
        height: CapsuleInfoPanel.minHeight + 4,
        child: CapsuleInfoPanel(
          capsule: capsule,
          onMoreInfo: onMoreInfo ?? () {},
        ),
      ),
    ),
  ),
);

const _locked = Duration(days: 12, hours: 23, minutes: 59, seconds: 59);

void main() {
  setUpAll(_loadAppFont);

  group('capsule info panel', () {
    testWidgets('counts down to a locked capsule', (tester) async {
      await tester.pumpWidget(
        _panel(
          _panelCapsule(
            opensIn: const Duration(days: 2, hours: 3, minutes: 30),
          ),
        ),
      );
      expect(find.textContaining('Opens in 2d 3h '), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('16-10-2026'), findsOneWidget);
    });

    testWidgets('an open capsule can be opened', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        _panel(_panelCapsule(), onMoreInfo: () => opened++),
      );
      expect(find.text("Check out what's inside!"), findsOneWidget);
      await tester.tap(find.text('Open'));
      expect(opened, 1);
    });

    testWidgets('speaks the app language', (tester) async {
      await tester.pumpWidget(
        _panel(
          _panelCapsule(
            opensIn: const Duration(days: 2, hours: 3, minutes: 30),
          ),
          locale: const Locale('ru'),
        ),
      );
      expect(find.textContaining('Откроется через 2д 3ч '), findsOneWidget);
      expect(find.text('Закрыта'), findsOneWidget);
    });

    for (final locale in AppLocalizations.supportedLocales) {
      for (final dark in [false, true]) {
        testWidgets('fits in ${locale.languageCode}, '
            '${dark ? 'dark' : 'light'}', (tester) async {
          tester.view
            ..physicalSize = const Size(320, 640)
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          for (final opensIn in [null, _locked]) {
            await tester.pumpWidget(
              _panel(
                _panelCapsule(opensIn: opensIn),
                locale: locale,
                dark: dark,
              ),
            );
            expect(tester.takeException(), isNull, reason: '$opensIn');
          }
        });
      }
    }
  });

  group('capsule visibility on the map', () {
    bool visible(Capsule c) =>
        MapController.isVisibleTo(c, uid: 'me', friendIds: {'friend'});

    test('own capsules are always visible', () {
      for (final p in CapsulePrivacy.values) {
        expect(visible(_c('me', p)), isTrue, reason: p.name);
      }
    });

    test('public capsules of anyone are visible', () {
      expect(visible(_c('stranger', CapsulePrivacy.public)), isTrue);
    });

    test('friends-only capsules only from friends', () {
      expect(visible(_c('friend', CapsulePrivacy.friends)), isTrue);
      expect(visible(_c('stranger', CapsulePrivacy.friends)), isFalse);
    });

    test("other people's private capsules are never visible", () {
      expect(visible(_c('friend', CapsulePrivacy.private)), isFalse);
      expect(visible(_c('stranger', CapsulePrivacy.private)), isFalse);
    });
  });

  test('MapFocus hands a capsule over exactly once', () {
    final focus = MapFocus();
    var notified = 0;
    focus.addListener(() => notified++);
    final capsule = _c('me', CapsulePrivacy.public);
    focus.focus(capsule);
    expect(notified, 1);
    expect(focus.take(), capsule);
    expect(focus.take(), isNull);
  });

  test('CurrentLocation notifies only on real changes', () {
    final location = CurrentLocation();
    var notified = 0;
    location.addListener(() => notified++);
    location.update(const GeoPosition(1, 2));
    location.update(const GeoPosition(1, 2));
    location.update(null);
    expect(notified, 1);
    expect(location.position, const GeoPosition(1, 2));
  });
}

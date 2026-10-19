// The map's own (i) button and credit line, the credits sheet, and the map
// notices on the licenses page (docs/map/ATTRIBUTION.md).
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/theme/app_dimens.dart';
import 'package:later/core/theme/app_theme.dart';
import 'package:later/features/map/map_licenses.dart';
import 'package:later/features/map/widgets/map_credits_control.dart';

import '../helpers/test_app.dart';

Widget _onMap({Locale locale = const Locale('en'), bool dark = false}) =>
    testApp(
      locale: locale,
      theme: dark ? AppTheme.dark : AppTheme.light,
      home: const Scaffold(
        body: Align(
          alignment: Alignment.bottomLeft,
          child: MapCreditsControl(maxWidth: 300),
        ),
      ),
    );

void main() {
  testWidgets('a 44 dp target with a label, the credit line next to it', (
    tester,
  ) async {
    await tester.pumpWidget(_onMap());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    final button = find.byType(MapCreditsButton);
    expect(tester.getSize(button), const Size.square(AppSizes.mapControl));
    expect(find.bySemanticsLabel('Map data and credits'), findsOneWidget);
    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
    expect(find.textContaining('© OpenMapTiles'), findsOneWidget);
  });

  testWidgets('the button opens the credits, with their links', (tester) async {
    tester.view
      ..physicalSize = const Size(412, 915)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_onMap());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MapCreditsButton));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Map data'), findsOneWidget);
    expect(find.text('Data from OpenStreetMap'), findsOneWidget);
    expect(find.text('© OpenMapTiles'), findsOneWidget);
    expect(find.text('Improve this map'), findsOneWidget);
    expect(find.text('Map rendered with MapLibre'), findsOneWidget);
  });

  for (final locale in const ['en', 'ru', 'pl', 'de', 'es']) {
    for (final dark in [false, true]) {
      testWidgets('fits a 320 dp phone at 130 % text, $locale, '
          '${dark ? 'dark' : 'light'}', (tester) async {
        tester.view
          ..physicalSize = const Size(320, 640)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: _onMap(locale: Locale(locale), dark: dark),
          ),
        );
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(MapCreditsButton));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  test('the licenses page lists MapLibre Native and the map data', () async {
    MapLicenses.register();
    final entries = await LicenseRegistry.licenses.toList();
    final names = {for (final e in entries) ...e.packages};
    for (final name in [
      'MapLibre Native',
      'OpenStreetMap data',
      'OpenMapTiles schema',
      'Noto Sans (map labels)',
    ]) {
      expect(names, contains(name));
    }
    final native = entries.firstWhere(
      (e) => e.packages.contains('MapLibre Native'),
    );
    expect(
      native.paragraphs.map((p) => p.text).join('\n'),
      contains('BSD 2-Clause'),
    );
  });
}

// The map's compass: hidden while the map faces north, shown (and tappable)
// while it is turned.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/theme/app_dimens.dart';
import 'package:later/features/map/widgets/map_compass.dart';

import '../helpers/test_app.dart';

void main() {
  test('a map turned by a degree or less faces north', () {
    expect(MapCompass.isTurned(0), isFalse);
    expect(MapCompass.isTurned(0.5), isFalse);
    expect(MapCompass.isTurned(359.5), isFalse);
    expect(MapCompass.isTurned(-0.5), isFalse);
    expect(MapCompass.isTurned(45), isTrue);
    expect(MapCompass.isTurned(-45), isTrue);
    expect(MapCompass.isTurned(358), isTrue);
  });

  testWidgets('shows only while the map is turned; a tap asks for north', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final bearing = ValueNotifier<double>(0);
    addTearDown(bearing.dispose);
    var taps = 0;
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: Center(
            child: MapCompass(bearing: bearing, onTap: () => taps++),
          ),
        ),
      ),
    );
    // The live semantics tree (a render object keeps its last node after
    // being excluded, so bySemanticsLabel would still see it).
    final label = find.semantics.byLabel('Turn the map to north');
    expect(label, findsNothing);
    await tester.tap(find.byType(MapCompass), warnIfMissed: false);
    expect(taps, 0);

    bearing.value = 90;
    await tester.pumpAndSettle();
    expect(label, findsOneWidget);
    // One scale for every map control, never under the 44 dp tap minimum.
    expect(
      tester.getSize(find.byType(MapCompass)),
      const Size.square(AppSizes.mapControl),
    );
    expect(AppSizes.mapControl, greaterThanOrEqualTo(44));
    await tester.tap(find.byType(MapCompass));
    expect(taps, 1);

    bearing.value = 0;
    await tester.pumpAndSettle();
    expect(label, findsNothing);
    semantics.dispose();
  });
}

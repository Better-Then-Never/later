import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/core/theme/app_theme.dart';
import 'package:later/shared/widgets/system_bar_fade.dart';

import '../helpers/test_app.dart';

void main() {
  Widget app({required double bar, ThemeData? theme, VoidCallback? onTap}) =>
      testApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(360, 800),
            padding: EdgeInsets.only(bottom: bar),
            viewPadding: EdgeInsets.only(bottom: bar),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: onTap,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SystemBarFade(),
              ),
            ],
          ),
        ),
      );

  LinearGradient gradient(WidgetTester tester) =>
      (tester
                      .widget<DecoratedBox>(
                        find.descendant(
                          of: find.byType(SystemBarFade),
                          matching: find.byType(DecoratedBox),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .gradient!
          as LinearGradient;

  double height(WidgetTester tester) =>
      tester.getSize(find.byType(SystemBarFade)).height;

  testWidgets('three buttons: 80 dp, clear at the top, 80 % at the bottom', (
    tester,
  ) async {
    await tester.pumpWidget(app(bar: 48));
    expect(height(tester), 80);
    final g = gradient(tester);
    expect(g.colors.first.a, 0);
    expect(g.colors.last.a, closeTo(0.8, 0.001));
    // The edge fills in over 24 dp, eased: halfway it is half of its 70 %.
    expect(g.stops![4], closeTo(24 / 80, 1e-9));
    expect(g.colors[4].a, closeTo(0.7, 0.001));
    expect(g.colors[2].a, closeTo(0.35, 0.001));
    expect(g.stops, orderedEquals([...g.stops!]..sort()));
  });

  testWidgets('gestures: 56 dp, the same 24 dp edge', (tester) async {
    await tester.pumpWidget(app(bar: 24));
    expect(height(tester), 56);
    expect(gradient(tester).stops![4], closeTo(24 / 56, 1e-9));
  });

  testWidgets('no bottom bar, or the keyboard up: nothing is drawn', (
    tester,
  ) async {
    await tester.pumpWidget(app(bar: 0));
    expect(
      find.descendant(
        of: find.byType(SystemBarFade),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('it is the page colour, light and dark', (tester) async {
    await tester.pumpWidget(app(bar: 48, theme: AppTheme.light));
    expect(
      gradient(tester).colors.last.withValues(alpha: 1),
      AppPalette.light.background,
    );
    await tester.pumpWidget(app(bar: 48, theme: AppTheme.dark));
    await tester.pumpAndSettle();
    expect(
      gradient(tester).colors.last.withValues(alpha: 1),
      AppPalette.dark.background,
    );
  });

  testWidgets('taps go through to what is under it', (tester) async {
    var taps = 0;
    await tester.pumpWidget(app(bar: 48, onTap: () => taps++));
    await tester.tapAt(tester.getCenter(find.byType(SystemBarFade)));
    expect(taps, 1);
  });
}

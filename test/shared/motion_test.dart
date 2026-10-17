import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/theme/app_motion.dart';
import 'package:later/shared/motion/app_motion_widgets.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(body: Center(child: child)),
  ),
);

double _scale(WidgetTester tester) =>
    tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

void main() {
  testWidgets('AppPressable scales down while pressed and still taps', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        AppPressable(
          child: TextButton(onPressed: () => taps++, child: const Text('Go')),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Go')),
    );
    await tester.pump();
    expect(_scale(tester), AppMotion.pressedScale);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);
    expect(taps, 1);
  });

  testWidgets('AppPressable adds no motion when animations are disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const AppPressable(child: Text('Go')), reduceMotion: true),
    );
    expect(find.byType(AnimatedScale), findsNothing);
  });

  testWidgets('AppEnter fades in, or shows at once when motion is reduced', (
    tester,
  ) async {
    // How far in it is: the fade (a thinning cover) and the lift share one
    // curve, read from the lift. 1 = fully in.
    double opacity() =>
        1 -
        tester
                .widget<SlideTransition>(
                  find.descendant(
                    of: find.byType(AppEnter),
                    matching: find.byType(SlideTransition),
                  ),
                )
                .position
                .value
                .dy /
            0.15;

    await tester.pumpWidget(_app(const AppEnter(child: Text('Hi'))));
    expect(opacity(), lessThan(1));
    // No opacity layer: on Impeller it draws the widget offscreen per frame.
    expect(
      find.descendant(
        of: find.byType(AppEnter),
        matching: find.byWidgetPredicate(
          (w) => w is FadeTransition || w is Opacity,
        ),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(opacity(), 1);

    await tester.pumpWidget(
      _app(const AppEnter(child: Text('Hi')), reduceMotion: true),
    );
    // A new state: the previous one was replaced by a reduced-motion tree.
    await tester.pump();
    expect(opacity(), 1);

    await tester.pumpWidget(
      _app(const AppEnter(animate: false, child: Text('Old'))),
    );
    expect(opacity(), 1);
  });

  test('AppMotion values come from the existing design', () {
    expect(AppMotion.fast, const Duration(milliseconds: 150));
    expect(AppMotion.emphasized, const Duration(milliseconds: 250));
  });

  testWidgets('the first rows of a list come in one after another, later ones '
      'simply appear', (tester) async {
    double opacity(String key) =>
        1 -
        tester
                .widget<SlideTransition>(
                  find
                      .descendant(
                        of: find.byKey(ValueKey(key)),
                        matching: find.byType(SlideTransition),
                      )
                      .first,
                )
                .position
                .value
                .dy /
            0.15;

    Widget list(int rows) => _app(
      AppStaggerScope(
        child: Column(
          children: [
            for (var i = 0; i < rows; i++)
              AppStaggerItem(
                key: ValueKey('row$i'),
                index: i,
                child: Text('row $i'),
              ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(list(3));
    await tester.pump(const Duration(milliseconds: 60));
    expect(opacity('row0'), greaterThan(0));
    expect(opacity('row2'), 0, reason: 'its turn comes 70 ms in');
    await tester.pumpAndSettle();
    expect(opacity('row2'), 1);

    // Well after the list appeared: a new row does not animate.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 700)),
    );
    await tester.pumpWidget(list(4));
    expect(opacity('row3'), 1);
  });
}

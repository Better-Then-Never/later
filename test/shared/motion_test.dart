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
    double opacity() => tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(AppEnter),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;

    await tester.pumpWidget(_app(const AppEnter(child: Text('Hi'))));
    expect(opacity(), lessThan(1));
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
}

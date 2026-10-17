import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/theme/app_motion.dart';
import 'package:later/shared/motion/reaction_burst.dart';

void main() {
  Widget app(bool active, {bool reduceMotion = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Center(
        child: ReactionBurst(active: active, child: const Text('❤️')),
      ),
    ),
  );

  double scale(WidgetTester tester) => tester
      .widget<ScaleTransition>(
        find.descendant(
          of: find.byType(ReactionBurst),
          matching: find.byType(ScaleTransition),
        ),
      )
      .scale
      .value;

  testWidgets('pops when the reaction becomes the user\'s, then settles', (
    tester,
  ) async {
    await tester.pumpWidget(app(false));
    await tester.pumpWidget(app(true));
    await tester.pump(AppMotion.reveal * 0.4);
    expect(scale(tester), greaterThan(1.2));
    await tester.pumpAndSettle();
    expect(scale(tester), 1);
  });

  testWidgets('a reaction that was already there does not pop', (tester) async {
    await tester.pumpWidget(app(true));
    await tester.pump(AppMotion.reveal * 0.4);
    expect(scale(tester), 1);
  });

  testWidgets('reduced motion: no pop', (tester) async {
    await tester.pumpWidget(app(false, reduceMotion: true));
    await tester.pumpWidget(app(true, reduceMotion: true));
    await tester.pump(AppMotion.reveal * 0.4);
    expect(scale(tester), 1);
  });
}

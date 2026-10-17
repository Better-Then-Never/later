import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/shared/motion/idle_float.dart';

void main() {
  Widget app({bool reduceMotion = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: const Center(child: IdleFloat(child: Text('icon'))),
    ),
  );

  double lift(WidgetTester tester) => tester
      .widget<Transform>(
        find
            .descendant(
              of: find.byType(IdleFloat),
              matching: find.byType(Transform),
            )
            .first,
      )
      .transform
      .getTranslation()
      .y;

  testWidgets('breathes twice, then rests where it started', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump(IdleFloat.breath ~/ 4);
    expect(lift(tester), lessThan(-1));
    await tester.pumpAndSettle();
    expect(lift(tester), moreOrLessEquals(0, epsilon: 1e-6));
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'it stops');
  });

  testWidgets('reduced motion: still', (tester) async {
    await tester.pumpWidget(app(reduceMotion: true));
    await tester.pump(IdleFloat.breath ~/ 4);
    expect(lift(tester), 0);
  });
}

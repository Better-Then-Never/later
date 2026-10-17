import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/shell/tab_stack.dart';
import 'package:later/core/theme/app_motion.dart';

class _Probe extends StatelessWidget {
  const _Probe(this.name);

  final String name;

  @override
  Widget build(BuildContext context) =>
      Text('$name ticking: ${TickerMode.of(context)}');
}

void main() {
  Widget app(int index, {bool reduceMotion = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: TabStack(index: index, children: const [_Probe('a'), _Probe('b')]),
    ),
  );

  double rise(WidgetTester tester) => tester
      .widget<Transform>(
        find
            .descendant(
              of: find.byType(TabStack),
              matching: find.byType(Transform),
            )
            .first,
      )
      .transform
      .getTranslation()
      .y;

  testWidgets('only the shown tab ticks', (tester) async {
    await tester.pumpWidget(app(0));
    expect(find.text('a ticking: true'), findsOneWidget);
    expect(find.text('b ticking: false', skipOffstage: false), findsOneWidget);
    await tester.pumpWidget(app(1));
    await tester.pumpAndSettle();
    expect(find.text('b ticking: true'), findsOneWidget);
    expect(find.text('a ticking: false', skipOffstage: false), findsOneWidget);
  });

  testWidgets('a tab rises into place, then rests', (tester) async {
    await tester.pumpWidget(app(0));
    expect(rise(tester), 0);
    await tester.pumpWidget(app(1));
    await tester.pump(AppMotion.fast ~/ 3);
    expect(rise(tester), greaterThan(0));
    await tester.pumpAndSettle();
    expect(rise(tester), 0);
  });

  testWidgets('with reduced motion the tab is just there', (tester) async {
    await tester.pumpWidget(app(0, reduceMotion: true));
    await tester.pumpWidget(app(1, reduceMotion: true));
    await tester.pump();
    expect(rise(tester), 0);
  });
}

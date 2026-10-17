import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/shared/widgets/count_badge.dart';

import '../helpers/test_app.dart';

Widget _inRow(Widget badge) => testApp(
  home: Scaffold(
    body: SizedBox(
      width: 400,
      child: ListTile(
        title: const Text('Bob'),
        trailing: Column(mainAxisSize: MainAxisSize.min, children: [badge]),
      ),
    ),
  ),
);

void main() {
  testWidgets('stays as small as its number inside a row', (tester) async {
    await tester.pumpWidget(_inRow(const CountBadge(count: 3)));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(CountBadge)), const Size(20, 20));

    await tester.pumpWidget(_inRow(const CountBadge(count: 120)));
    await tester.pumpAndSettle();
    expect(find.text('99+'), findsOneWidget);
    expect(tester.getSize(find.byType(CountBadge)).width, lessThan(60));
  });

  testWidgets('a screen reader hears the count in the app language', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_inRow(const CountBadge(count: 3)));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp(r'\b3 new\b')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('takes no space at zero', (tester) async {
    await tester.pumpWidget(_inRow(const CountBadge(count: 0)));
    expect(tester.getSize(find.byType(CountBadge)), Size.zero);
  });
}

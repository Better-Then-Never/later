import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/shared/widgets/count_badge.dart';

Widget _inRow(Widget badge) => MaterialApp(
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

  testWidgets('takes no space at zero', (tester) async {
    await tester.pumpWidget(_inRow(const CountBadge(count: 0)));
    expect(tester.getSize(find.byType(CountBadge)), Size.zero);
  });
}

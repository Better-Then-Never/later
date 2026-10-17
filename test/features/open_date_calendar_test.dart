// The capsule's own calendar (F-27, B4).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/capsules/creation/widgets/open_date_calendar.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('a tap chooses a day; days before the first are not offered', (
    tester,
  ) async {
    DateTime? chosen;
    await tester.pumpWidget(
      testApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => chosen = await OpenDateCalendar.show(
              context,
              first: DateTime(2030, 3, 10),
              last: DateTime(2031, 12, 31),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('March 2030'), findsOneWidget);

    // The 9th is before the first day: nothing happens.
    await tester.tap(find.text('9'));
    await tester.pumpAndSettle();
    expect(chosen, isNull);
    expect(find.text('March 2030'), findsOneWidget);

    // The next month, then the 1st.
    await tester.tap(find.bySemanticsLabel('Next month'));
    await tester.pumpAndSettle();
    expect(find.text('April 2030'), findsOneWidget);
    await tester.tap(find.text('1').first);
    await tester.pumpAndSettle();
    expect(chosen, DateTime(2030, 4, 1));
  });

  testWidgets('weeks start on Monday in Russian, months are capitalised', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        locale: const Locale('ru'),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => OpenDateCalendar.show(
              context,
              first: DateTime(2030, 3, 10),
              last: DateTime(2031, 12, 31),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Март 2030 г.'), findsOneWidget);
    final initials = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .toList();
    expect(initials.indexOf('П'), lessThan(initials.indexOf('В')));
  });
}

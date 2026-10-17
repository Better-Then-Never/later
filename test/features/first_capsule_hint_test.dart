import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/map/widgets/first_capsule_hint.dart';
import 'package:later/shared/widgets/buttons/default_icon_button.dart';

import '../helpers/test_app.dart';

void main() {
  for (final lang in ['en', 'ru', 'pl', 'de', 'es']) {
    testWidgets('the first-capsule hint fits a narrow phone in $lang', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(360, 700)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var taps = 0;
      var closed = 0;
      await tester.pumpWidget(
        testApp(
          locale: Locale(lang),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: FirstCapsuleHint(
                  onTap: () => taps++,
                  onClose: () => closed++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'no overflow');
      expect(
        tester.getSize(find.byType(FirstCapsuleHint)).height,
        FirstCapsuleHint.height,
      );
      await tester.tap(find.byType(FirstCapsuleHint));
      await tester.tap(find.byType(DefaultIconButton));
      expect((taps, closed), (1, 1));
    });
  }
}

// "typing…" under the friend's name: its dots move, except with reduced
// motion, and a screen reader hears it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/messages/widgets/typing_label.dart';

import '../helpers/test_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required bool reduced}) =>
      tester.pumpWidget(
        testApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: const Scaffold(body: TypingLabel(text: 'typing')),
          ),
        ),
      );

  testWidgets('the dots wave while it shows', (tester) async {
    await pump(tester, reduced: false);
    expect(find.text('typing'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    // Leaving stops the wave (no ticker left behind).
    await tester.pumpWidget(const SizedBox());
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('still with reduced motion; read out as it appears', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester, reduced: true);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(
      tester.getSemantics(find.byType(TypingLabel)),
      matchesSemantics(label: 'typing', isLiveRegion: true),
    );
    semantics.dispose();
  });
}

// Tap targets of at least 44 × 44 for the controls the phone audit found too
// small (docs/feel/FEEL_QA.md, "Tap targets"). The phone audit itself is
// tool/dev/tap_audit.sh; this keeps the fixed ones from shrinking again.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/features/map/widgets/first_capsule_hint.dart';
import 'package:later/features/messages/widgets/reply_bar.dart';
import 'package:later/shared/widgets/buttons/default_icon_button.dart';

import '../helpers/test_app.dart';

const _minimum = MinimumTapTargetGuideline(
  size: Size(44, 44),
  link: 'docs/feel/FEEL_QA.md',
);

void main() {
  /// The phone of docs/feel/DEVICE.md: 360 × 800 dp.
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('a small icon button still has a 44 dp target', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      DefaultIconButton(
        onTap: () {},
        assetPath: AppIcons.capsuleClose,
        size: 22,
        semanticLabel: 'Close',
      ),
    );
    expect(tester.getSize(find.byType(DefaultIconButton)), const Size(44, 44));
    await expectLater(tester, meetsGuideline(_minimum));
    semantics.dispose();
  });

  testWidgets('the default icon button size meets the minimum', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      DefaultIconButton(
        onTap: () {},
        assetPath: AppIcons.settings,
        semanticLabel: 'Settings',
      ),
    );
    await expectLater(tester, meetsGuideline(_minimum));
    semantics.dispose();
  });

  testWidgets('the reply bar closes from a 44 dp target', (tester) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      SizedBox(
        width: 360,
        child: ReplyBar(name: 'Bob', text: 'See you at six', onCancel: () {}),
      ),
    );
    await expectLater(tester, meetsGuideline(_minimum));
    semantics.dispose();
  });

  testWidgets('the first-capsule hint closes from a 44 dp target', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(
      tester,
      SizedBox(
        width: 360,
        child: FirstCapsuleHint(onTap: () {}, onClose: () {}),
      ),
    );
    await expectLater(tester, meetsGuideline(_minimum));
    semantics.dispose();
  });
}

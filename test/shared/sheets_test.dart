import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/features/history/widgets/menu_item_node.dart';
import 'package:later/features/history/widgets/nested_menu.dart';
import 'package:later/shared/widgets/app_sheets.dart';
import 'package:later/shared/widgets/buttons/default_icon_button.dart';
import 'package:later/shared/widgets/confirm_dialog.dart';

import '../helpers/test_app.dart';

/// A page with a button that runs [open] with the page's context.
Widget _launcher(void Function(BuildContext) open) => testApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => open(context),
          child: const Text('open'),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a centred sheet closes on a tap outside, not inside (F-32)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _launcher(
        (context) => showCenteredSheet<void>(
          context,
          const SizedBox(width: 200, height: 100, child: Text('card')),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('card'));
    await tester.pumpAndSettle();
    expect(find.text('card'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('card'), findsNothing);
  });

  testWidgets('the confirmation card shows its message and confirms once', (
    tester,
  ) async {
    var confirmed = 0;
    await tester.pumpWidget(
      _launcher(
        (context) => ConfirmDialog.show(
          context: context,
          title: 'Revoke?',
          message: 'Open the settings to do it.',
          confirmText: 'Open settings',
          onConfirm: () => confirmed++,
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Open the settings to do it.'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(confirmed, 1);
    expect(find.text('Revoke?'), findsNothing);
  });

  testWidgets('nested menu: current choice in green, submenu and back', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      _launcher(
        (context) => showCenteredSheet<void>(
          context,
          NestedMenu(
            title: 'Sort By',
            rootItems: [
              MenuItemNode(label: 'Reset', onTap: () => picked = 'reset'),
              MenuItemNode(
                label: 'Relevance',
                children: [
                  MenuItemNode(label: 'Oldest', onTap: () => picked = 'old'),
                  MenuItemNode(
                    label: 'Newest',
                    onTap: () => picked = 'new',
                    selected: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    Color? colorOf(String text) => tester
        .widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text(text),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        )
        .style
        .color;
    expect(colorOf('Relevance'), AppColors.brandGreen, reason: 'holds it');
    expect(colorOf('Reset'), isNot(AppColors.brandGreen));

    await tester.tap(find.text('Relevance'));
    await tester.pumpAndSettle();
    expect(find.text('Oldest'), findsOneWidget);
    expect(colorOf('Newest'), AppColors.brandGreen);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Reset'), findsOneWidget);

    await tester.tap(find.text('Relevance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Oldest'));
    await tester.pumpAndSettle();
    expect(picked, 'old');
    expect(find.text('Sort By'), findsNothing, reason: 'closed after a pick');
  });

  testWidgets('icon buttons can be read by a screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: DefaultIconButton(
            onTap: () {},
            semanticLabel: 'New Chat',
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('New Chat'), findsOneWidget);
    semantics.dispose();
  });
}

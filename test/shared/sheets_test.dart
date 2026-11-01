import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/features/history/widgets/menu_item_node.dart';
import 'package:later/features/history/widgets/nested_menu.dart';
import 'package:later/shared/widgets/app_sheets.dart';
import 'package:later/shared/widgets/buttons/default_icon_button.dart';
import 'package:later/shared/widgets/confirm_dialog.dart';
import 'package:later/shared/widgets/options_menu.dart';

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

/// The opened capsule's shape: the handle, the square picture with a
/// button on it, words under it.
Widget _sheet() => const SheetSurface(
  color: AppColors.onMedia,
  radius: 28,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SheetHandle.v2(),
      Flexible(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: SheetPicture(
                  radius: 20,
                  over: [
                    Positioned(
                      top: 10,
                      right: 10,
                      child: SizedBox(
                        key: ValueKey('button'),
                        width: 36,
                        height: 36,
                      ),
                    ),
                  ],
                  child: ColoredBox(
                    key: ValueKey('photo'),
                    color: AppColors.brandGreen,
                  ),
                ),
              ),
              SizedBox(height: 200),
            ],
          ),
        ),
      ),
    ],
  ),
);

void main() {
  group('a sheet growing out of a thumbnail', () {
    const thumb = Rect.fromLTWH(26, 600, 76, 76);
    final photo = find.byKey(const ValueKey('photo'));
    final surface = find.byType(SheetSurface);

    Future<void> open(WidgetTester tester, {SheetOrigin? origin}) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _launcher(
          (context) => Navigator.of(context).push(
            AppSheetRoute<void>(
              origin: origin,
              barrierColor: AppColors.mediaScrim,
              barrierLabel: 'close',
              builder: (_) => _sheet(),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      // The first frame lays the sheet out unseen (heroes measure it).
      await tester.pump();
    }

    double buttonFade(WidgetTester tester) => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byKey(const ValueKey('button')),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    testWidgets('the picture starts on the thumbnail and never leaves its '
        'place on the sheet', (tester) async {
      await open(tester, origin: const SheetOrigin(thumb, radius: 14));
      await tester.pump(const Duration(milliseconds: 1));
      final first = tester.getRect(photo);
      expect(first.left, closeTo(thumb.left, 2));
      expect(first.top, closeTo(thumb.top, 2));
      expect(first.width, closeTo(thumb.width, 4));
      expect(buttonFade(tester), lessThan(0.1));
      var width = first.width;
      for (var ms = 0; ms < 260; ms += 20) {
        await tester.pump(const Duration(milliseconds: 20));
        final now = tester.getRect(photo);
        // Right under the handle (20 dp) all the way: the sheet and its
        // picture move as one.
        expect(now.top - tester.getRect(surface).top, closeTo(20, 0.01));
        expect(now.width, greaterThanOrEqualTo(width - 0.01));
        width = now.width;
      }
      await tester.pumpAndSettle();
      expect(tester.getRect(photo), const Rect.fromLTWH(16, 216, 368, 368));
      expect(buttonFade(tester), 1);

      // Closing: back into the thumbnail the same way.
      await tester.tapAt(const Offset(200, 40));
      await tester.pump();
      for (var ms = 0; ms < 240; ms += 20) {
        await tester.pump(const Duration(milliseconds: 20));
        final now = tester.getRect(photo);
        expect(now.top - tester.getRect(surface).top, closeTo(20, 0.01));
        expect(now.width, lessThanOrEqualTo(width + 0.01));
        width = now.width;
      }
      final last = tester.getRect(photo);
      expect(last.top, closeTo(thumb.top, 3));
      expect(last.left, closeTo(thumb.left, 3));
      await tester.pumpAndSettle();
      expect(photo, findsNothing);
    });

    testWidgets('without one it rises from below the screen, whole', (
      tester,
    ) async {
      await open(tester);
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.getRect(photo).top, greaterThan(800));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getRect(photo).width, 368);
      expect(buttonFade(tester), 1);
      await tester.pumpAndSettle();
      expect(tester.getRect(photo), const Rect.fromLTWH(16, 216, 368, 368));
    });
  });

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

  testWidgets('a choice menu marks the current value and returns the tap', (
    tester,
  ) async {
    String? picked;
    await tester.pumpWidget(
      _launcher((context) async {
        picked = await showChoiceMenu<String>(
          context,
          title: 'Privacy',
          selected: 'friends',
          choices: const [
            MenuChoice('public', 'Public'),
            MenuChoice('friends', 'Friends'),
            MenuChoice('private', 'Private'),
          ],
        );
      }),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final friends = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Friends'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    expect(friends.style.color, AppColors.brandGreen);
    // The title has the theme's text style, not Flutter's fallback (yellow
    // double underline when a card has no Material above it).
    expect(
      DefaultTextStyle.of(
        tester.element(find.text('Privacy')),
      ).style.decoration,
      isNot(TextDecoration.underline),
    );
    expect(
      find.ancestor(of: find.text('Privacy'), matching: find.byType(Material)),
      findsWidgets,
    );
    await tester.tap(find.text('Private'));
    await tester.pumpAndSettle();
    expect(picked, 'private');
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

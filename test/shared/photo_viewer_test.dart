import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/appearance/ui_scale_view.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/shared/widgets/photo_viewer.dart';

Widget _app({required double scale}) => MaterialApp(
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  // As LaterApp: the navigator inside the scale view and the snow stack.
  builder: (context, child) => UiScaleView(
    scale: scale,
    child: Stack(children: [child ?? const SizedBox()]),
  ),
  home: Builder(
    builder: (context) => Center(
      child: TextButton(
        onPressed: () => showDialog<void>(
          context: context,
          builder: (dialog) => Dialog(
            child: TextButton(
              onPressed: () => PhotoViewer.show(dialog, 'file:///nope.jpg'),
              child: const Text('photo'),
            ),
          ),
        ),
        child: const Text('open'),
      ),
    ),
  ),
);

void main() {
  for (final scale in [1.0, 1.15]) {
    testWidgets(
      'the photo fills the screen, opened from a dialog (scale $scale)',
      (tester) async {
        await tester.pumpWidget(_app(scale: scale));
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('photo'));
        await tester.pumpAndSettle();
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        // The photo area itself, not only the page (it once shrank to the
        // Back button inside a full-screen page).
        expect(tester.getSize(find.byType(InteractiveViewer)), screen / scale);
        expect(tester.getTopLeft(find.byType(InteractiveViewer)), Offset.zero);
      },
    );
  }

  testWidgets('double tap zooms in and out; a drag down closes it', (
    tester,
  ) async {
    await tester.pumpWidget(_app(scale: 1));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('photo'));
    await tester.pumpAndSettle();
    final viewer = find.byType(InteractiveViewer);
    double zoom() => tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!
        .value
        .getMaxScaleOnAxis();

    Future<void> doubleTap() async {
      await tester.tapAt(const Offset(200, 300));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(const Offset(200, 300));
      await tester.pumpAndSettle();
    }

    await doubleTap();
    expect(zoom(), closeTo(2.5, 0.01));
    await doubleTap();
    expect(zoom(), closeTo(1, 0.01));

    // In small steps, like a finger (one jump would be a pan).
    await tester.timedDragFrom(
      const Offset(200, 300),
      const Offset(0, 200),
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsNothing);
    expect(find.text('photo'), findsOneWidget, reason: 'back on the dialog');
  });

  testWidgets('with a hero tag the photo flies; no page-wide fade', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Center(
            child: GestureDetector(
              onTap: () =>
                  PhotoViewer.show(context, 'file:///nope.jpg', heroTag: 'p'),
              child: const Hero(
                tag: 'p',
                child: SizedBox(width: 80, height: 80, child: Text('thumb')),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('thumb'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // Mid-flight: the viewer's photo is a hero, and nothing fades the page.
    expect(
      find.byWidgetPredicate((w) => w is Hero && w.tag == 'p'),
      findsWidgets,
    );
    expect(
      find.ancestor(
        of: find.byType(PhotoViewer),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(find.byType(PhotoViewer), findsOneWidget);
  });
}

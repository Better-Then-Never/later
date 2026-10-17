import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/router/app_page_route.dart';
import 'package:later/core/theme/app_motion.dart';

void main() {
  late GlobalKey<NavigatorState> navigator;

  Widget app({bool reduceMotion = false}) {
    navigator = GlobalKey<NavigatorState>();
    return MaterialApp(
      navigatorKey: navigator,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: const Scaffold(body: Center(child: Text('home'))),
    );
  }

  Widget page({bool canPop = true}) => PopScope(
    canPop: canPop,
    child: const Scaffold(body: Center(child: Text('page'))),
  );

  double pageLeft(WidgetTester tester) =>
      tester.getTopLeft(find.text('page')).dx -
      (tester.getSize(find.byType(Scaffold).last).width -
              tester.getSize(find.text('page')).width) /
          2;

  testWidgets('a page slides in from the right and settles', (tester) async {
    await tester.pumpWidget(app());
    unawaited(navigator.currentState!.push(appRoute<void>(page())));
    await tester.pump();
    await tester.pump(AppMotion.emphasized ~/ 3);
    expect(pageLeft(tester), greaterThan(0));
    await tester.pumpAndSettle();
    expect(pageLeft(tester), moreOrLessEquals(0));
  });

  testWidgets('no page-wide fade: transitions are transforms only', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    unawaited(navigator.currentState!.push(appRoute<void>(page())));
    await tester.pump();
    await tester.pump(AppMotion.emphasized ~/ 2);
    expect(
      find.ancestor(
        of: find.text('page'),
        matching: find.byWidgetPredicate(
          (w) => w is FadeTransition || w is Opacity,
        ),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
  });

  testWidgets('a swipe from the left edge past half the width goes back', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    unawaited(navigator.currentState!.push(appRoute<void>(page())));
    await tester.pumpAndSettle();
    final width = tester.getSize(find.byType(MaterialApp)).width;
    final gesture = await tester.startGesture(const Offset(5, 300));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(Offset(width * 0.06, 0));
      await tester.pump(const Duration(milliseconds: 50));
    }
    // It follows the finger.
    expect(pageLeft(tester), greaterThan(width * 0.5));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('page'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('a short swipe springs back', (tester) async {
    await tester.pumpWidget(app());
    unawaited(navigator.currentState!.push(appRoute<void>(page())));
    await tester.pumpAndSettle();
    final gesture = await tester.startGesture(const Offset(5, 300));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
    expect(pageLeft(tester), moreOrLessEquals(0));
  });

  testWidgets('a page that cannot be left cannot be swiped away', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    unawaited(
      navigator.currentState!.push(appRoute<void>(page(canPop: false))),
    );
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(5, 300), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('a swipe that starts away from the edge does nothing', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    unawaited(navigator.currentState!.push(appRoute<void>(page())));
    await tester.pumpAndSettle();
    await tester.dragFrom(const Offset(120, 300), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.text('page'), findsOneWidget);
  });

  testWidgets('with reduced motion the page is there at once', (tester) async {
    await tester.pumpWidget(app(reduceMotion: true));
    unawaited(navigator.currentState!.push(appRoute<void>(page())));
    await tester.pump();
    await tester.pump();
    expect(pageLeft(tester), moreOrLessEquals(0));
    await tester.pumpAndSettle();
  });

  testWidgets('a sheet page rises from the bottom', (tester) async {
    await tester.pumpWidget(app());
    unawaited(navigator.currentState!.push(appSheetRoute<void>(page())));
    await tester.pump();
    await tester.pump(AppMotion.emphasized ~/ 3);
    final screen = tester.getSize(find.byType(MaterialApp)).height;
    expect(tester.getCenter(find.text('page')).dy, greaterThan(screen / 2));
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.text('page')).dy,
      moreOrLessEquals(screen / 2),
    );
  });
}

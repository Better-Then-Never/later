import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/profile_stamp.dart';
import 'package:later/features/profile/postcard/postcard_scroll.dart';
import 'package:later/features/profile/postcard/profile_postcard.dart';
import 'package:later/shared/widgets/user/profile_stamp.dart';

import '../helpers/test_app.dart';

ScrollMetrics _metrics(double pixels) => FixedScrollMetrics(
  minScrollExtent: 0,
  maxScrollExtent: 2000,
  pixels: pixels,
  viewportDimension: 800,
  axisDirection: AxisDirection.down,
  devicePixelRatio: 1,
);

void main() {
  late BuildContext ctx;
  setUp(() {});

  testWidgets('a pull at the top opens the postcard; scrolling closes it', (
    tester,
  ) async {
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox();
        },
      ),
    );
    final s = PostcardScroll();
    final drag = DragUpdateDetails(globalPosition: Offset.zero);
    for (var i = 0; i < 3; i++) {
      s.onScroll(
        OverscrollNotification(
          metrics: _metrics(0),
          context: ctx,
          overscroll: -20,
          dragDetails: drag,
        ),
        stripAt: 300,
      );
    }
    expect(s.open, isFalse, reason: '60 of 64 pulled');
    s.onScroll(
      OverscrollNotification(
        metrics: _metrics(0),
        context: ctx,
        overscroll: -10,
        dragDetails: drag,
      ),
      stripAt: 300,
    );
    expect(s.open, isTrue);
    // Stays open while resting at the top.
    s.onScroll(
      ScrollEndNotification(metrics: _metrics(0), context: ctx),
      stripAt: 300,
    );
    expect(s.open, isTrue);
    s.onScroll(
      ScrollUpdateNotification(metrics: _metrics(40), context: ctx),
      stripAt: 300,
    );
    expect(s.open, isFalse);
  });

  testWidgets('iOS bounce: pulled past the top opens it too', (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox();
        },
      ),
    );
    final s = PostcardScroll();
    s.onScroll(
      ScrollUpdateNotification(
        metrics: _metrics(-80),
        context: ctx,
        dragDetails: DragUpdateDetails(globalPosition: Offset.zero),
      ),
      stripAt: 300,
    );
    expect(s.open, isTrue);
  });

  testWidgets('the strip shows only past its threshold', (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox();
        },
      ),
    );
    final s = PostcardScroll();
    var notified = 0;
    s.addListener(() => notified++);
    s.onScroll(
      ScrollUpdateNotification(metrics: _metrics(200), context: ctx),
      stripAt: 300,
    );
    expect(s.strip, isFalse);
    s.onScroll(
      ScrollUpdateNotification(metrics: _metrics(320), context: ctx),
      stripAt: 300,
    );
    s.onScroll(
      ScrollUpdateNotification(metrics: _metrics(400), context: ctx),
      stripAt: 300,
    );
    expect(s.strip, isTrue);
    expect(notified, 1, reason: 'one change, one rebuild');
  });

  testWidgets('the postcard: photo height, stamp, words and numbers', (
    tester,
  ) async {
    Widget card(double photo) => testApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ProfilePostcard(
            photoHeight: photo,
            cover: const ColoredBox(
              key: ValueKey('cover'),
              color: Color(0xFF336699),
            ),
            stamp: const ProfileStamp(
              style: ProfileStampStyle(shape: StampShape.round),
              size: ProfilePostcard.stampSize,
              initial: 'A',
            ),
            name: const Text('Alice Walker'),
            subtitle: const Text('@alice  ·  Warszawa'),
            about: const StampSpeechBubble(child: Text('Collecting moments')),
            counts: const Text('30 followers'),
          ),
        ),
      ),
    );
    await tester.pumpWidget(card(ProfilePostcard.photoDefault));
    expect(find.text('Alice Walker'), findsOneWidget);
    expect(find.text('Collecting moments'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('cover'))).height,
      ProfilePostcard.photoDefault,
    );
    await tester.pumpWidget(card(ProfilePostcard.photoOpen));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('cover'))).height,
      ProfilePostcard.photoOpen,
    );
  });
}

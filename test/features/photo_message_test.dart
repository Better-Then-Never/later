// Photo messages in a chat: their bubble keeps the photo's shape, shows the
// caption, and opens the photo when tapped.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/chat.dart';
import 'package:later/features/messages/widgets/message_bubble.dart';
import 'package:later/features/messages/widgets/photo_message.dart';

import '../helpers/test_app.dart';

ChatMessage _photo({
  String text = ChatMessage.photoSign,
  int? width = 1200,
  int? height = 1600,
  MessageDelivery delivery = MessageDelivery.sent,
}) => ChatMessage(
  id: 'p1',
  senderId: 'me',
  text: text,
  type: ChatMessageType.image,
  imagePath: 'chats/bob_me/me/p1.jpg',
  width: width,
  height: height,
  delivery: delivery,
  sentAt: DateTime(2026, 10, 17, 9, 30),
  // A file that does not exist: the bubble keeps its shape regardless.
  localPath: '/nowhere/p1.jpg',
);

void main() {
  test('the bubble takes the photo shape, within limits', () {
    const screen = Size(360, 800);
    // 3:4 portrait, 62 % of the width wide.
    expect(
      PhotoMessage.displaySize(_photo(), screen),
      const Size(360 * 0.62, 360 * 0.62 * 4 / 3),
    );
    // Very tall: capped at 42 % of the height, at most 1:2.
    final tall = PhotoMessage.displaySize(
      _photo(width: 100, height: 1000),
      screen,
    );
    expect(tall.height, closeTo(800 * 0.42, 0.01));
    expect(tall.width, closeTo(tall.height / 2, 0.01));
    // No size known yet: 3:4.
    expect(
      PhotoMessage.displaySize(_photo(width: null, height: null), screen),
      const Size(360 * 0.62, 360 * 0.62 * 4 / 3),
    );
  });

  Future<void> pump(
    WidgetTester tester,
    ChatMessage message, {
    VoidCallback? onTap,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: Center(
            child: MessageBubble(
              message: message,
              isMine: true,
              onPhotoTap: onTap,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a caption shows under the photo; the camera sign does not', (
    tester,
  ) async {
    await pump(tester, _photo(text: 'At the lake'));
    expect(find.text('At the lake'), findsOneWidget);
    final size = tester.getSize(find.byType(PhotoMessage));
    expect(size.width, closeTo(223.2, 0.01));
    expect(size.height, closeTo(297.6, 0.01));

    await pump(tester, _photo());
    expect(find.text(ChatMessage.photoSign), findsNothing);
  });

  testWidgets('tapping opens it; while sending a ring turns on it', (
    tester,
  ) async {
    var taps = 0;
    await pump(tester, _photo(), onTap: () => taps++);
    await tester.tap(find.byType(PhotoMessage));
    expect(taps, 1);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await pump(tester, _photo(delivery: MessageDelivery.sending));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

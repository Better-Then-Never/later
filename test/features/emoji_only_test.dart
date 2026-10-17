// One to three emoji alone are shown large, like stickers; the sticker panel
// sends one in a tap and remembers it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/data/models/chat.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/messages/emoji_only.dart';
import 'package:later/features/messages/widgets/message_bubble.dart';
import 'package:later/features/messages/widgets/sticker_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_app.dart';

void main() {
  test('counts emoji alone, with skin tones, families and flags', () {
    expect(EmojiOnly.count('😀'), 1);
    expect(EmojiOnly.count(' 🎉 '), 1);
    expect(EmojiOnly.count('😀 😀'), 2);
    expect(EmojiOnly.count('👍🏽'), 1);
    expect(EmojiOnly.count('👨‍👩‍👧'), 1);
    expect(EmojiOnly.count('🇵🇱'), 1);
    expect(EmojiOnly.count('❤️❤️❤️'), 3);
    // Not large: words, digits, signs, four or more, nothing.
    expect(EmojiOnly.count('hi'), isNull);
    expect(EmojiOnly.count('😀 hi'), isNull);
    expect(EmojiOnly.count('1'), isNull);
    expect(EmojiOnly.count('#'), isNull);
    expect(EmojiOnly.count('😀😀😀😀'), isNull);
    expect(EmojiOnly.count('  '), isNull);
  });

  ChatMessage text(String t, {MessageReply? reply}) => ChatMessage(
    id: 'm',
    senderId: 'me',
    text: t,
    sentAt: DateTime(2026, 10, 17, 9),
    replyTo: reply,
  );

  Future<void> pump(WidgetTester tester, ChatMessage message) =>
      tester.pumpWidget(
        testApp(
          home: Scaffold(body: MessageBubble(message: message, isMine: true)),
        ),
      );

  testWidgets('emoji alone are large and without a bubble', (tester) async {
    await pump(tester, text('🎉'));
    final big = tester.widget<Text>(find.text('🎉'));
    expect(big.style?.fontSize, EmojiOnly.size(1));
    expect(
      find.byWidgetPredicate(
        (w) => w is Container && w.decoration is BoxDecoration,
      ),
      findsNothing,
    );

    // A reply keeps its bubble (the quote needs it); words stay normal.
    await pump(
      tester,
      text(
        '🎉',
        reply: const MessageReply(id: 'q', senderId: 'bob', text: 'x'),
      ),
    );
    expect(tester.widget<Text>(find.text('🎉')).style?.fontSize, isNot(56));
    await pump(tester, text('Yes 🎉'));
    expect(tester.widget<Text>(find.text('Yes 🎉')).style?.fontSize, isNot(56));
  });

  testWidgets('the panel sends one in a tap and keeps it among the recent', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesStore();
    String? picked;
    Widget app() => MultiProvider(
      providers: [
        Provider<PreferencesStore>.value(value: prefs),
        ChangeNotifierProvider<SessionController>.value(value: _FakeSession()),
      ],
      child: testApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => picked = await StickerSheet.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.pumpWidget(app());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Recently used'), findsNothing);
    await tester.tap(find.text('🥳'));
    await tester.pumpAndSettle();
    expect(picked, '🥳');
    expect(await prefs.string('me', 'recent_stickers'), '🥳');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text('Recently used'), findsOneWidget);
  });
}

class _FakeSession extends ChangeNotifier implements SessionController {
  @override
  String? get uid => 'me';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Voice messages: the loudness bars, the one-at-a-time player (against a
// mocked native channel), sending through the controller, and the bubble.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/chat.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/services/voice_service.dart';
import 'package:later/features/friends/friends_store.dart';
import 'package:later/features/messages/chat_controller.dart';
import 'package:later/features/messages/chats_store.dart';
import 'package:later/features/messages/voice_player.dart';
import 'package:later/features/messages/widgets/voice_message.dart';
import 'package:later/features/messages/widgets/voice_recorder_bar.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

const _channel = MethodChannel('later.app/voice');

ChatMessage _voice({
  String id = 'v1',
  String? localPath = '/phone/v1.m4a',
  MessageDelivery delivery = MessageDelivery.sent,
}) => ChatMessage(
  id: id,
  senderId: 'me',
  text: ChatMessage.voiceSign,
  type: ChatMessageType.voice,
  localPath: localPath,
  durationMs: 4200,
  waveform: List.generate(40, (i) => i * 2),
  delivery: delivery,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return switch (call.method) {
            'play' => 4200,
            'position' => 1500,
            'stop' => 4200,
            'amplitude' => 12000,
            _ => null,
          };
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null),
  );

  group('waveform', () {
    test('40 bars of 0-100, the loudest at 100, stretched or squeezed', () {
      expect(VoiceRecorderBar.waveform(const []), List.filled(40, 0));
      expect(VoiceRecorderBar.waveform(const [0, 0, 0]), List.filled(40, 0));

      final rising = VoiceRecorderBar.waveform(
        List.generate(400, (i) => i * 80),
      );
      expect(rising.length, 40);
      expect(rising.last, 100);
      expect(rising.first, lessThan(rising.last));
      expect(rising.every((b) => b >= 0 && b <= 100), isTrue);

      final few = VoiceRecorderBar.waveform(const [100, 32767, 50]);
      expect(few.length, 40);
      expect(few.reduce((a, b) => a > b ? a : b), 100);
    });
  });

  group('VoicePlayer', () {
    test(
      'plays the phone\'s file, shows progress, pauses and resumes',
      () async {
        final player = VoicePlayer(VoiceService());
        expect(await player.toggle(_voice()), isTrue);
        expect(calls.map((c) => c.method), ['play']);
        expect(calls.single.arguments, {'path': '/phone/v1.m4a'});
        expect(player.isPlaying('v1'), isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 130));
        expect(player.positionOf('v1'), 1500);
        expect(player.progressOf('v1'), closeTo(1500 / 4200, 0.001));

        expect(await player.toggle(_voice()), isTrue);
        expect(player.isPlaying('v1'), isFalse);
        expect(calls.last.method, 'pause');
        expect(await player.toggle(_voice()), isTrue);
        expect(calls.last.method, 'resume');

        // Another message stops this one first.
        await player.toggle(_voice(id: 'v2', localPath: '/phone/v2.m4a'));
        expect(calls.map((c) => c.method), contains('stopPlayback'));
        expect(player.isPlaying('v1'), isFalse);
        expect(player.isPlaying('v2'), isTrue);

        // The end of the recording, reported by the platform.
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
              _channel.name,
              _channel.codec.encodeMethodCall(const MethodCall('completed')),
              (_) {},
            );
        await pumpEventQueue();
        expect(player.isPlaying('v2'), isFalse);
        player.dispose();
      },
    );

    test('a message without a recording cannot be played', () async {
      final player = VoicePlayer(VoiceService());
      expect(await player.toggle(_voice(localPath: null)), isFalse);
      expect(player.isPlaying('v1'), isFalse);
      player.dispose();
    });
  });

  group('sending', () {
    late FakeChatRepository repo;
    late ChatsStore chats;
    late FriendsStore friends;

    setUp(() async {
      repo = FakeChatRepository();
      chats = ChatsStore(repo)..attach('me');
      friends = FriendsStore(
        friends: FakeFriendsRepository(),
        users: FakeUserRepository()
          ..put(const UserProfile(uid: 'bob', name: 'Bob', username: 'bob')),
        notifications: FakeNotificationRepository(),
      )..attach('me');
      await pumpEventQueue();
    });

    test(
      'a recording shows at once, uploads once, and goes as voice',
      () async {
        final c = ChatController(
          friendUid: 'bob',
          chats: chats,
          friends: friends,
        );
        await pumpEventQueue();
        final bars = List.generate(40, (i) => i);
        final sending = c.sendVoice(
          '/phone/r.m4a',
          durationMs: 3100,
          waveform: bars,
        );
        expect(c.messages.single.type, ChatMessageType.voice);
        expect(c.messages.single.delivery, MessageDelivery.sending);
        expect(await sending, isNull);
        await pumpEventQueue();
        final sent = c.messages.single;
        expect(sent.delivery, MessageDelivery.sent);
        expect(sent.durationMs, 3100);
        expect(sent.waveform, bars);
        expect(sent.localPath, '/phone/r.m4a');
        expect(sent.audioPath, endsWith('.m4a'));
        expect(repo.calls.where((x) => x.startsWith('uploadvoice:')).length, 1);
        expect(chats.chatWith('bob')!.lastMessage, ChatMessage.voiceSign);

        c.replyTo(sent);
        expect(c.replyingTo!.text, '${ChatMessage.voiceSign} Voice message');
        expect(await c.deleteMessage(sent), isNull);
        expect(repo.calls.last, endsWith(sent.audioPath!));
        c.dispose();
      },
    );
  });

  testWidgets('the bubble: play button, bars and length', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: Center(
            child: ChangeNotifierProvider(
              create: (_) => VoicePlayer(VoiceService()),
              child: VoiceMessageView(message: _voice(), onGreen: true),
            ),
          ),
        ),
      ),
    );
    expect(find.text('0:04'), findsOneWidget);
    expect(find.bySemanticsLabel('Play voice message'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Play voice message'));
    await tester.pump();
    await tester.pump();
    expect(calls.map((c) => c.method), contains('play'));
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    // Leave: playback stops with the chat.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 200));
    expect(calls.map((c) => c.method), contains('stopPlayback'));
    semantics.dispose();
  });
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/firebase/firestore_mappers.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/chat.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/services/location_service.dart';
import 'package:later/features/capsules/creation/capsule_creation_controller.dart';
import 'package:later/features/friends/friends_store.dart';
import 'package:later/features/map/current_location.dart';
import 'package:later/features/messages/chat_controller.dart';
import 'package:later/features/messages/chat_time.dart';
import 'package:later/features/messages/chats_store.dart';

import '../fakes/fake_repositories.dart';

class _NoLocation extends LocationService {
  @override
  Future<GeoPosition?> currentPosition({
    Duration timeout = const Duration(seconds: 8),
    bool request = false,
  }) async => null;
}

void main() {
  late FakeChatRepository chatRepo;
  late FakeFriendsRepository friendsRepo;
  late FakeUserRepository users;
  late ChatsStore chats;
  late FriendsStore friends;

  setUp(() async {
    chatRepo = FakeChatRepository();
    friendsRepo = FakeFriendsRepository();
    users = FakeUserRepository()
      ..put(const UserProfile(uid: 'me', name: 'Me', username: 'me'))
      ..put(const UserProfile(uid: 'bob', name: 'Bob', username: 'bob'));
    chats = ChatsStore(chatRepo)..attach('me');
    friends = FriendsStore(
      friends: friendsRepo,
      users: users,
      notifications: FakeNotificationRepository(),
    )..attach('me');
    await pumpEventQueue();
  });

  group('Chat', () {
    test('both sides compute the same id; no chat with yourself', () {
      expect(Chat.idBetween('b', 'a'), 'a_b');
      expect(Chat.idBetween('a', 'b'), 'a_b');
      expect(() => Chat.idBetween('a', 'a'), throwsArgumentError);
    });

    test('reads the documents the app on main wrote', () {
      final chat = FirestoreMappers.chat('a_b', {
        'participants': ['b', 'a'],
        'lastMessage': 'hi',
        'lastUpdated': Timestamp.fromDate(DateTime(2026, 1, 2)),
      });
      expect(chat.otherThan('a'), 'b');
      expect(chat.lastSenderId, isNull);
      expect(chat.lastUpdated, DateTime(2026, 1, 2));

      final text = FirestoreMappers.chatMessage('m', {
        'senderId': 'a',
        'text': 'hi',
        'status': 'read',
      });
      expect(text.isRead, isTrue);
      expect(text.isCapsule, isFalse);
      expect(text.sentAt, isNull, reason: 'server time still pending');

      final capsule = FirestoreMappers.chatMessage('m2', {
        'senderId': 'a',
        'text': 'Trip',
        'status': 'sent',
        'type': 'capsule',
        'capsuleId': 'c1',
        'imageUrl': 'https://img',
      });
      expect(capsule.isCapsule, isTrue);
      expect(capsule.isRead, isFalse);
    });

    test('a capsule for a friend is shared with both of you', () {
      final data = FirestoreMappers.newCapsule(
        const CapsuleDraft(
          ownerId: 'me',
          title: 'T',
          privacy: CapsulePrivacy.private,
          color: CapsuleColor.red,
          location: GeoPosition(1, 2),
          imagePath: 'x',
          recipientId: 'bob',
        ),
        imageUrl: 'https://img',
      );
      expect(data['sharedWith'], ['me', 'bob']);
      expect(
        FirestoreMappers.capsule('c', {...data, 'location': null}).sharedWith,
        ['me', 'bob'],
      );
    });
  });

  group('Photo messages', () {
    test('read from the server, tolerant of missing or odd sizes', () {
      final photo = FirestoreMappers.chatMessage('p', {
        'senderId': 'a',
        'text': ChatMessage.photoSign,
        'status': 'sent',
        'type': 'image',
        'imageUrl': 'https://x/p.jpg',
        'imagePath': 'chats/a_b/a/p.jpg',
        'width': 1200,
        'height': 1600,
      });
      expect(photo.type, ChatMessageType.image);
      expect(photo.isPhoto, isTrue);
      expect(photo.caption, '', reason: 'the camera sign is not a caption');
      expect((photo.width, photo.height), (1200, 1600));
      expect(photo.imagePath, 'chats/a_b/a/p.jpg');

      final odd = FirestoreMappers.chatMessage('q', {
        'senderId': 'a',
        'text': 'Look',
        'type': 'image',
        'imageUrl': 'https://x/q.jpg',
        'width': 0,
        'height': 'big',
      });
      expect(odd.caption, 'Look');
      expect((odd.width, odd.height), (null, null));

      // A type this version does not know reads as text.
      expect(
        FirestoreMappers.chatMessage('r', {
          'text': 'hi',
          'type': 'sticker',
        }).type,
        ChatMessageType.text,
      );
    });
  });

  group('ChatTime', () {
    final now = DateTime(2026, 10, 16, 12);

    // The labels are formatted in the app's language; the app gets the date
    // symbols from flutter_localizations, a plain test loads them here.
    setUpAll(initializeDateFormatting);

    test('chat list labels', () {
      expect(ChatTime.listLabel(null, now), '12:00');
      expect(ChatTime.listLabel(DateTime(2026, 10, 16, 9, 5), now), '09:05');
      expect(ChatTime.listLabel(DateTime(2026, 10, 15, 23), now), 'Yesterday');
      expect(ChatTime.listLabel(DateTime(2026, 10, 12, 8), now), 'Monday');
      expect(ChatTime.listLabel(DateTime(2026, 10, 9), now), '09.10.2026');
    });

    test('day separators', () {
      expect(ChatTime.dayLabel(null, now), 'Today');
      expect(ChatTime.dayLabel(DateTime(2026, 10, 16, 1), now), 'Today');
      expect(ChatTime.dayLabel(DateTime(2026, 10, 15, 23), now), 'Yesterday');
      expect(ChatTime.dayLabel(DateTime(2026, 9, 1), now), 'September 1, 2026');
    });
  });

  var sent = 0;
  Future<void> say(String from, String to, String text) => chatRepo.sendText(
    from: from,
    to: to,
    text: text,
    messageId: 'x${sent++}',
  );

  group('ChatsStore', () {
    test('lists chats with messages and follows the session', () async {
      expect(chats.isLoaded, isTrue);
      expect(chats.chats, isEmpty);

      expect(await chats.sendText('bob', 'hi', messageId: 'a'), isNull);
      await pumpEventQueue();
      expect(chats.chats.single.lastMessage, 'hi');

      expect(await chats.clearHistory('bob'), isNull);
      await pumpEventQueue();
      expect(chats.chats, isEmpty, reason: 'cleared chats leave the list');

      chats.detach();
      expect(chats.uid, isNull);
      expect(
        await chats.sendText('bob', 'x', messageId: 'b'),
        isA<AuthFailure>(),
      );
    });

    test('counts unread messages, except in muted chats', () async {
      await say('bob', 'me', 'one');
      await say('bob', 'me', 'two');
      await say('me', 'carol', 'mine are not unread for me');
      await say('carol', 'me', 'three');
      await pumpEventQueue();
      expect(chats.totalUnread, 3);
      expect(chats.chatWith('bob')!.unreadFor('me'), 2);

      chats.muted = {Chat.idBetween('me', 'bob')};
      expect(chats.totalUnread, 1);
    });

    test('a failed send is reported, not thrown', () async {
      chatRepo.failSends = true;
      final failure = await chats.sendText('bob', 'hi', messageId: 'a');
      expect(failure?.message, 'Failed to send message');
    });
  });

  group('ChatController', () {
    ChatController open({int pageSize = 50}) => ChatController(
      friendUid: 'bob',
      chats: chats,
      friends: friends,
      pageSize: pageSize,
    );

    test('shows the conversation and marks it read with one write', () async {
      await say('bob', 'me', 'Hello');
      final c = open();
      await pumpEventQueue();

      expect(c.isLoaded, isTrue);
      expect(c.visibleMessages.single.text, 'Hello');
      expect(c.isMine(c.visibleMessages.single), isFalse);
      expect(chatRepo.calls.where((x) => x.startsWith('read:')), [
        'read:bob_me:me',
      ]);
      expect(chats.chatWith('bob')!.unreadFor('me'), 0);

      // A message arriving while the chat is open is marked read too.
      chatRepo.calls.clear();
      await say('bob', 'me', 'Still there?');
      await pumpEventQueue();
      expect(chatRepo.calls, contains('read:bob_me:me'));
      c.dispose();
    });

    test('a message shows at once; its receipt goes sent, then read', () async {
      final c = open();
      await pumpEventQueue();
      expect(c.receipt, isNull);

      final sending = c.send('  hi  ');
      expect(c.messages.single.text, 'hi', reason: 'shown before the server');
      expect(c.receipt, ReceiptStatus.sending);
      expect(await sending, isNull);
      await pumpEventQueue();
      expect(c.messages.single.delivery, MessageDelivery.sent);
      expect(c.receipt, ReceiptStatus.sent);

      chatRepo.now = chatRepo.now.add(const Duration(minutes: 1));
      await chatRepo.markRead(Chat.idBetween('me', 'bob'), reader: 'bob');
      await pumpEventQueue();
      expect(c.receipt, ReceiptStatus.read);

      await say('bob', 'me', 'reply');
      await pumpEventQueue();
      expect(c.receipt, isNull, reason: 'the friend wrote last');
      c.dispose();
    });

    test('reopening a chat shows its messages at once (F-03)', () async {
      await say('bob', 'me', 'Hello');
      final first = open();
      await pumpEventQueue();
      expect(first.visibleMessages.single.text, 'Hello');
      first.dispose();

      final again = open();
      expect(again.isLoaded, isTrue, reason: 'no spinner on re-entry');
      expect(again.visibleMessages.single.text, 'Hello');
      again.dispose();

      chats.detach();
      expect(chats.recentWith('bob'), isNull, reason: 'forgotten on sign-out');
    });

    test('with read receipts off nothing is told and nothing shown', () async {
      await say('bob', 'me', 'Hello');
      final c = ChatController(
        friendUid: 'bob',
        chats: chats,
        friends: friends,
        readReceipts: () => false,
      );
      await pumpEventQueue();
      expect(chatRepo.calls, contains('unread0:bob_me:me'));
      expect(chatRepo.calls.where((x) => x.startsWith('read:')), isEmpty);
      expect(chats.chatWith('bob')!.unreadFor('me'), 0);

      expect(await c.send('hi'), isNull);
      chatRepo.now = chatRepo.now.add(const Duration(minutes: 1));
      await chatRepo.markRead(Chat.idBetween('me', 'bob'), reader: 'bob');
      await pumpEventQueue();
      expect(c.receipt, ReceiptStatus.sent);
      c.dispose();
    });

    test('a failed message stays, can be retried, and never doubles', () async {
      final c = open();
      await pumpEventQueue();
      chatRepo.failSends = true;
      expect(await c.send('hi'), isNotNull);
      expect(c.messages.single.delivery, MessageDelivery.failed);
      expect(c.receipt, ReceiptStatus.failed);

      chatRepo.failSends = false;
      final id = c.messages.single.id;
      expect(await c.retry(id), isNull);
      await pumpEventQueue();
      expect(c.messages, hasLength(1));
      expect(c.messages.single.delivery, MessageDelivery.sent);
      // Retrying an id that already arrived changes nothing.
      expect(await c.retry(id), isNull);
      expect(chatRepo.messages[Chat.idBetween('me', 'bob')], hasLength(1));
      c.dispose();
    });

    test('deleting your newest message: gone at once, the summary goes back '
        'to the one before', () async {
      await say('bob', 'me', 'Hello');
      final c = open();
      await pumpEventQueue();
      expect(await c.send('oops'), isNull);
      await pumpEventQueue();
      final mine = c.messages.last;
      expect(c.canDelete(mine), isTrue);
      expect(c.canDelete(c.messages.first), isFalse, reason: "Bob's");

      final deleting = c.deleteMessage(mine);
      expect(c.messages.map((m) => m.text), ['Hello'], reason: 'at once');
      expect(await deleting, isNull);
      await pumpEventQueue();
      expect(c.messages.map((m) => m.text), ['Hello']);
      final chat = chats.chatWith('bob')!;
      expect(chat.lastMessage, 'Hello');
      expect(chat.lastSenderId, 'bob', reason: 'not "You: Hello"');
      c.dispose();
    });

    test('a refused delete brings the message back; an unsent one is only '
        'dropped here', () async {
      final c = open();
      await pumpEventQueue();
      expect(await c.send('kept'), isNull);
      await pumpEventQueue();
      chatRepo.failSends = true;
      expect(await c.deleteMessage(c.messages.single), isNotNull);
      expect(c.messages.single.text, 'kept');

      expect(await c.send('never sent'), isNotNull);
      final failed = c.messages.last;
      expect(failed.delivery, MessageDelivery.failed);
      chatRepo.calls.clear();
      expect(await c.deleteMessage(failed), isNull);
      expect(c.messages.map((m) => m.text), ['kept']);
      expect(chatRepo.calls.where((x) => x.startsWith('delete:')), isEmpty);
      c.dispose();
    });

    test('a reply quotes the message, also after a failed send', () async {
      await say('bob', 'me', 'Coming tonight?');
      final c = open();
      await pumpEventQueue();
      final question = c.messages.single;
      expect(c.canReply(question), isTrue);

      c.replyTo(question);
      expect(c.replyingTo?.text, 'Coming tonight?');
      c.cancelReply();
      expect(c.replyingTo, isNull);

      c.replyTo(question);
      chatRepo.failSends = true;
      expect(await c.send('Yes'), isNotNull);
      expect(c.replyingTo, isNull, reason: 'the bar closes once sent');
      final failed = c.messages.last;
      expect(failed.replyTo?.id, question.id, reason: 'shown with its quote');
      expect(c.canReply(failed), isFalse, reason: 'not on the server');

      chatRepo.failSends = false;
      expect(await c.retry(failed.id), isNull);
      await pumpEventQueue();
      final sent = chatRepo.messages[Chat.idBetween('me', 'bob')]!.last;
      expect(sent.replyTo, MessageReply.of(question));
      c.dispose();
    });

    test('reacting: shown at once, the same emoji again takes it back, '
        'refused ones roll back', () async {
      await say('bob', 'me', 'Look at this');
      final c = open();
      await pumpEventQueue();
      final m = c.messages.single;

      final reacting = c.react(m, ReactionType.heart);
      expect(c.messages.single.reactions['me'], ReactionType.heart);
      expect(await reacting, isNull);
      await pumpEventQueue();
      expect(chatRepo.messages[Chat.idBetween('me', 'bob')]!.single.reactions, {
        'me': ReactionType.heart,
      });

      // Another emoji replaces it; the same one again removes it.
      await c.react(c.messages.single, ReactionType.fire);
      await pumpEventQueue();
      expect(c.messages.single.reactions['me'], ReactionType.fire);
      await c.react(c.messages.single, ReactionType.fire);
      await pumpEventQueue();
      expect(c.messages.single.reactions, isEmpty);

      chatRepo.failSends = true;
      expect(await c.react(c.messages.single, ReactionType.wow), isNotNull);
      expect(c.messages.single.reactions, isEmpty, reason: 'rolled back');
      c.dispose();
    });

    test('reactions are read from the document; unknown ones skipped', () {
      final m = FirestoreMappers.chatMessage('m', {
        'senderId': 'bob',
        'text': 'hi',
        'reactions': {'me': 'heart', 'bob': 'laser', 'x': 3},
      });
      expect(m.reactions, {'me': ReactionType.heart});
    });

    test('a quote keeps the start of a long message', () {
      final long = ChatMessage(id: 'x', senderId: 'bob', text: '🙂' * 200);
      final quote = MessageReply.of(long);
      expect(quote.text.runes.length, MessageReply.maxText + 1);
      expect(quote.text.endsWith('…'), isTrue);
      expect(
        FirestoreMappers.messageReply(FirestoreMappers.newMessageReply(quote)),
        quote,
      );
      expect(FirestoreMappers.messageReply({'id': 'x'}), isNull);
      expect(FirestoreMappers.messageReply('x'), isNull);
    });

    test('refuses empty and too long messages', () async {
      final c = open();
      await pumpEventQueue();
      expect(await c.send('   '), isNull);
      expect(chatRepo.calls.where((x) => x.startsWith('text:')), isEmpty);
      final long = 'x' * (Chat.maxMessageLength + 1);
      expect(await c.send(long), isA<ValidationFailure>());
      expect(c.messages, isEmpty);
      c.dispose();
    });

    test('loads older messages a page at a time', () async {
      for (var i = 0; i < 12; i++) {
        await say(i.isEven ? 'bob' : 'me', i.isEven ? 'me' : 'bob', 'm$i');
      }
      final c = open(pageSize: 5);
      await pumpEventQueue();
      expect(c.messages.map((m) => m.text), ['m7', 'm8', 'm9', 'm10', 'm11']);
      expect(c.canLoadOlder, isTrue);

      c.loadOlder();
      await pumpEventQueue();
      expect(c.messages, hasLength(10));
      c.loadOlder();
      await pumpEventQueue();
      expect(c.messages, hasLength(12));
      expect(c.canLoadOlder, isFalse);
      expect(c.messages.first.text, 'm0');
      c.dispose();
    });

    test('search filters the messages', () async {
      await say('me', 'bob', 'Lunch?');
      await say('bob', 'me', 'Sure, lunch at 1');
      await say('me', 'bob', 'Great');
      final c = open();
      await pumpEventQueue();

      c.toggleSearch();
      c.search('LUNCH');
      expect(c.visibleMessages.map((m) => m.text), [
        'Lunch?',
        'Sure, lunch at 1',
      ]);
      c.toggleSearch();
      expect(c.query, isEmpty);
      expect(c.visibleMessages, hasLength(3));
      c.dispose();
    });

    test('nobody can write once either side blocked the other', () async {
      final c = open();
      await pumpEventQueue();
      expect(c.canSend, isTrue);

      expect(await friends.block('bob'), isNull);
      await pumpEventQueue();
      expect(friends.isBlocked('bob'), isTrue);
      expect(c.iBlockedThem, isTrue);
      expect(c.canSend, isFalse);

      expect(await friends.unblock('bob'), isNull);
      await pumpEventQueue();
      expect(c.canSend, isTrue);
      c.dispose();

      await friendsRepo.block(me: 'bob', other: 'me');
      final blocked = open();
      await pumpEventQueue();
      expect(blocked.blockedByThem, isTrue);
      expect(blocked.canSend, isFalse);
      blocked.dispose();
    });
  });

  group('ChatController photos', () {
    ChatController open() =>
        ChatController(friendUid: 'bob', chats: chats, friends: friends);

    test(
      'a photo shows at once, uploads, sends; the phone keeps its file',
      () async {
        final c = open();
        await pumpEventQueue();

        final sending = c.sendPhoto('/phone/p.jpg', caption: '  Look  ');
        final shown = c.messages.single;
        expect(shown.type, ChatMessageType.image);
        expect(shown.localPath, '/phone/p.jpg');
        expect(shown.delivery, MessageDelivery.sending);
        expect(shown.caption, 'Look');

        expect(await sending, isNull);
        await pumpEventQueue();
        final sent = c.messages.single;
        expect(sent.delivery, MessageDelivery.sent);
        expect(
          sent.imageUrl,
          startsWith('https://storage.test/chats/bob_me/me/'),
        );
        expect((sent.width, sent.height), (1200, 1600));
        expect(sent.localPath, '/phone/p.jpg', reason: 'never reloads here');
        expect(chatRepo.calls.where((x) => x.startsWith('upload:')).length, 1);
        expect(
          chatRepo.calls.last,
          startsWith('photo:me->bob:chats/bob_me/me/'),
        );
        expect(chats.chatWith('bob')!.lastMessage, 'Look');
        c.dispose();
      },
    );

    test(
      'a failed upload is retried; a failed send does not upload twice',
      () async {
        final c = open();
        await pumpEventQueue();

        chatRepo.failUploads = true;
        expect(await c.sendPhoto('/phone/p.jpg'), isNotNull);
        final failed = c.messages.single;
        expect(failed.delivery, MessageDelivery.failed);
        expect(c.receipt, ReceiptStatus.failed);

        // Uploaded on the retry, but the message itself is refused.
        chatRepo
          ..failUploads = false
          ..failSends = true;
        expect(await c.retry(failed.id), isNotNull);
        expect(chatRepo.calls.where((x) => x.startsWith('upload:')).length, 2);

        chatRepo.failSends = false;
        expect(await c.retry(failed.id), isNull);
        await pumpEventQueue();
        expect(
          chatRepo.calls.where((x) => x.startsWith('upload:')).length,
          2,
          reason: 'the photo was already uploaded',
        );
        expect(c.messages.single.delivery, MessageDelivery.sent);
        expect(c.messages.single.caption, '');
        expect(chats.chatWith('bob')!.lastMessage, ChatMessage.photoSign);
        c.dispose();
      },
    );

    test(
      'a reply to a photo quotes it in words; deleting takes the file',
      () async {
        final c = open();
        await pumpEventQueue();
        await c.sendPhoto('/phone/p.jpg');
        await pumpEventQueue();
        final photo = c.messages.single;

        c.replyTo(photo);
        expect(c.replyingTo!.text, '${ChatMessage.photoSign} Photo');

        expect(await c.deleteMessage(photo), isNull);
        expect(
          chatRepo.calls.last,
          'delete:bob_me:${photo.id}:${photo.imagePath}',
        );
        c.dispose();
      },
    );
  });

  group('Typing', () {
    ChatController open() => ChatController(
      friendUid: 'bob',
      chats: chats,
      friends: friends,
      typingRefresh: const Duration(milliseconds: 200),
      typingShown: const Duration(milliseconds: 150),
    );
    List<String> hints() =>
        chatRepo.calls.where((c) => c.startsWith('typing:')).toList();

    test(
      'the friend hears it at most every few seconds; sending stops it',
      () async {
        final c = open();
        await pumpEventQueue();
        c
          ..onInputChanged('h')
          ..onInputChanged('he')
          ..onInputChanged('hel');
        await pumpEventQueue();
        expect(hints(), ['typing:bob_me:me:true']);

        await Future<void>.delayed(const Duration(milliseconds: 220));
        c.onInputChanged('hell');
        await pumpEventQueue();
        expect(hints().length, 2);

        await c.send('hello');
        await pumpEventQueue();
        expect(hints().last, 'typing:bob_me:me:false');

        // Clearing the field stops it too; nothing to stop twice.
        c.onInputChanged('x');
        c.onInputChanged('');
        c.onInputChanged('');
        await pumpEventQueue();
        expect(hints().sublist(3), [
          'typing:bob_me:me:true',
          'typing:bob_me:me:false',
        ]);
        c.dispose();
      },
    );

    test(
      "the friend's hint shows, then fades without news; their message ends it",
      () async {
        final c = open();
        await pumpEventQueue();
        expect(c.friendTyping, isFalse);

        chatRepo.hint('bob_me', 'bob', DateTime.now());
        await pumpEventQueue();
        expect(c.friendTyping, isTrue);
        await Future<void>.delayed(const Duration(milliseconds: 170));
        expect(c.friendTyping, isFalse, reason: 'no hint for a while');

        chatRepo.hint('bob_me', 'bob', DateTime.now());
        await pumpEventQueue();
        expect(c.friendTyping, isTrue);
        await say('bob', 'me', 'there');
        await pumpEventQueue();
        expect(c.friendTyping, isFalse, reason: 'the message arrived');

        chatRepo.hint('bob_me', 'bob', DateTime.now());
        await pumpEventQueue();
        chatRepo.hint('bob_me', 'bob', null);
        await pumpEventQueue();
        expect(c.friendTyping, isFalse, reason: 'they stopped');
        c.dispose();
      },
    );

    test('a hint left over from long ago does not count', () async {
      chatRepo.hint(
        'bob_me',
        'bob',
        DateTime.now().subtract(const Duration(hours: 2)),
      );
      final c = open();
      await pumpEventQueue();
      expect(c.friendTyping, isFalse);
      c.dispose();
    });
  });

  group('Send a capsule to a friend', () {
    CapsuleCreationController build(FakeCapsuleRepository capsules) =>
        CapsuleCreationController(
          ownerId: 'me',
          imagePath: 'does/not/exist.jpg',
          capsules: capsules,
          location: _NoLocation(),
          currentLocation: CurrentLocation()..update(const GeoPosition(1, 2)),
          recipientId: 'bob',
          chats: chatRepo,
        );

    test(
      'private by default, shared with the friend, posted to the chat',
      () async {
        final capsules = FakeCapsuleRepository();
        final c = build(capsules);
        expect(c.privacy, CapsulePrivacy.private);
        c.titleController.text = 'For you';

        expect(await c.save(), isNull);
        expect(capsules.created.single.recipientId, 'bob');
        expect(chatRepo.calls, ['capsule:me->bob:cap-1']);
        final message = chatRepo.messages['bob_me']!.single;
        expect(message.isCapsule, isTrue);
        expect(message.text, 'For you');
        c.dispose();
      },
    );

    test('when only the chat post fails, a retry does not create the '
        'capsule twice', () async {
      final capsules = FakeCapsuleRepository();
      final c = build(capsules);
      chatRepo.failSends = true;
      expect(await c.save(), isNotNull);
      expect(capsules.created, hasLength(1));

      chatRepo.failSends = false;
      expect(await c.save(), isNull);
      expect(capsules.created, hasLength(1));
      expect(chatRepo.messages['bob_me'], hasLength(1));
      c.dispose();
    });
  });
}

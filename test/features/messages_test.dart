import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
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

  group('ChatTime', () {
    final now = DateTime(2026, 10, 16, 12);

    test('chat list labels', () {
      expect(ChatTime.listLabel(null, now), '');
      expect(ChatTime.listLabel(now, now), 'Now');
      expect(ChatTime.listLabel(DateTime(2026, 10, 16, 11, 55), now), '5m');
      expect(ChatTime.listLabel(DateTime(2026, 10, 16, 9), now), '3h');
      expect(ChatTime.listLabel(DateTime(2026, 10, 14, 12), now), '2d');
      expect(ChatTime.listLabel(DateTime(2026, 9, 1), now), '1/9');
    });

    test('day separators', () {
      expect(ChatTime.dayLabel(null, now), 'Today');
      expect(ChatTime.dayLabel(DateTime(2026, 10, 16, 1), now), 'Today');
      expect(ChatTime.dayLabel(DateTime(2026, 10, 15, 23), now), 'Yesterday');
      expect(ChatTime.dayLabel(DateTime(2026, 9, 1), now), 'September 1, 2026');
    });
  });

  group('ChatsStore', () {
    test('lists chats with messages and follows the session', () async {
      expect(chats.isLoaded, isTrue);
      expect(chats.chats, isEmpty);

      expect(await chats.sendText('bob', 'hi'), isNull);
      await pumpEventQueue();
      expect(chats.chats.single.lastMessage, 'hi');

      expect(await chats.clearHistory('bob'), isNull);
      await pumpEventQueue();
      expect(chats.chats, isEmpty, reason: 'cleared chats leave the list');

      chats.detach();
      expect(chats.uid, isNull);
      expect(await chats.sendText('bob', 'x'), isA<AuthFailure>());
    });

    test('a failed send is reported, not thrown', () async {
      chatRepo.failSends = true;
      final failure = await chats.sendText('bob', 'hi');
      expect(failure?.message, 'Failed to send message');
    });
  });

  group('ChatController', () {
    ChatController open() =>
        ChatController(friendUid: 'bob', chats: chats, friends: friends);

    test(
      'shows the conversation and marks what the friend sent as read',
      () async {
        await chatRepo.sendText(from: 'bob', to: 'me', text: 'Hello');
        final c = open();
        await pumpEventQueue();

        expect(c.isLoaded, isTrue);
        expect(c.visibleMessages.single.text, 'Hello');
        expect(c.isMine(c.visibleMessages.single), isFalse);
        expect(chatRepo.calls, contains('read:bob_me:bob'));
        expect(c.visibleMessages.single.isRead, isTrue);

        // A message arriving while the chat is open is marked read too.
        chatRepo.calls.clear();
        await chatRepo.sendText(from: 'bob', to: 'me', text: 'Still there?');
        await pumpEventQueue();
        expect(chatRepo.calls, contains('read:bob_me:bob'));
        c.dispose();
      },
    );

    test('sends trimmed text, refuses empty and too long messages', () async {
      final c = open();
      await pumpEventQueue();
      expect(await c.send('   '), isNull);
      expect(chatRepo.calls.where((x) => x.startsWith('text:')), isEmpty);

      expect(await c.send('  hi  '), isNull);
      expect(chatRepo.calls, contains('text:me->bob:hi'));

      final long = 'x' * (Chat.maxMessageLength + 1);
      expect(await c.send(long), isA<ValidationFailure>());
      c.dispose();
    });

    test('search filters the messages', () async {
      await chatRepo.sendText(from: 'me', to: 'bob', text: 'Lunch?');
      await chatRepo.sendText(from: 'bob', to: 'me', text: 'Sure, lunch at 1');
      await chatRepo.sendText(from: 'me', to: 'bob', text: 'Great');
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
        expect(chatRepo.calls, ['capsule:me->bob:new-1']);
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

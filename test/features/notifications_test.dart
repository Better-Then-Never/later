import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/data/models/app_notification.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:later/data/services/push_messaging_service.dart';
import 'package:later/features/notifications/notification_texts.dart';
import 'package:later/features/notifications/notifications_store.dart';
import 'package:later/features/notifications/widgets/notification_item.dart';
import 'package:later/features/notifications/widgets/notification_selection_action_bar.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

AppNotification _n(
  String id, {
  bool read = false,
  NotificationType type = NotificationType.follow,
  String message = 'started following you',
}) => AppNotification(
  id: id,
  type: type,
  fromUserName: 'bob',
  message: message,
  isRead: read,
  fromUserId: 'bob-uid',
);

String _sentence(AppNotification n) {
  final s = NotificationTexts.sentence(n);
  return '${s.before}${n.fromUserName}${s.after}';
}

void main() {
  group('NotificationsStore', () {
    late FakeNotificationRepository repo;
    late NotificationsStore store;

    setUp(() {
      repo = FakeNotificationRepository();
      store = NotificationsStore(repo);
    });

    test('follows the session: loads on attach, clears on detach', () async {
      repo.put('alice', [_n('1'), _n('2', read: true)]);
      store.attach('alice');
      await pumpEventQueue();
      expect(store.isLoaded, isTrue);
      expect(store.notifications.map((n) => n.id), ['1', '2']);
      expect(store.unreadCount, 1);

      repo.put('alice', [_n('0'), _n('1'), _n('2', read: true)]);
      await pumpEventQueue();
      expect(store.unreadCount, 2, reason: 'realtime updates (BUG-020)');

      store.detach();
      expect(store.notifications, isEmpty);
      expect(store.unreadCount, 0);
    });

    test('markRead and delete address notifications by id', () async {
      repo.put('alice', [_n('a'), _n('b'), _n('c')]);
      store.attach('alice');
      await pumpEventQueue();

      await store.markRead(['b', 'missing']);
      expect(repo.calls, ['markRead:b']);
      expect(store.notifications.firstWhere((n) => n.id == 'b').isRead, isTrue);
      expect(
        store.notifications.firstWhere((n) => n.id == 'a').isRead,
        isFalse,
      );

      await store.markRead(['b']);
      expect(repo.calls, ['markRead:b'], reason: 'already read: no write');

      await store.delete(['a']);
      await pumpEventQueue();
      expect(store.notifications.map((n) => n.id), ['b', 'c']);
    });
  });

  group('NotificationTap', () {
    test('parses the data payload sent by the Cloud Functions', () {
      final follow = NotificationTap.fromData({
        'type': 'follow',
        'userId': 'u1',
        'userName': 'bob',
        'clickAction': 'FLUTTER_NOTIFICATION_CLICK',
      });
      expect(follow.type, NotificationType.follow);
      expect(follow.userId, 'u1');
      expect(follow.capsuleId, isNull);

      final capsule = NotificationTap.fromData({
        'type': 'capsule',
        'userId': 'u2',
        'capsuleId': 'c9',
      });
      expect(capsule.type, NotificationType.capsule);
      expect(capsule.capsuleId, 'c9');

      final message = NotificationTap.fromData({
        'type': 'message',
        'userId': 'alice',
        'chatId': 'alice_bob',
        'messageId': 'm1',
      });
      expect(message.type, NotificationType.message);
      expect(message.userId, 'alice');
      expect(message.chatId, 'alice_bob');

      expect(NotificationTap.fromData({}).type, NotificationType.other);
      expect(NotificationTap.fromData({'userId': ''}).userId, isNull);
    });

    test('builds a tap from an in-app notification', () {
      final tap = NotificationTap.fromNotification(_n('x'));
      expect(tap.type, NotificationType.follow);
      expect(tap.userId, 'bob-uid');
    });
  });

  group('NotificationTexts', () {
    setUpAll(initializeDateFormatting);

    test('known types are written from the type, not the stored text', () {
      expect(
        _sentence(_n('1', message: 'anything')),
        'bob started following you',
      );
      expect(
        _sentence(_n('2', type: NotificationType.capsule, message: '')),
        'bob created a new capsule',
      );
      expect(
        _sentence(_n('3', type: NotificationType.message)),
        'bob sent you a message',
      );
    });

    test('comments and replies keep what the person wrote', () {
      expect(
        _sentence(_n('1', type: NotificationType.comment, message: 'Wow!')),
        'bob commented: Wow!',
      );
      expect(
        _sentence(_n('2', type: NotificationType.comment, message: ' ')),
        'bob commented on your capsule',
      );
      expect(
        _sentence(_n('3', type: NotificationType.reply, message: 'Thanks')),
        'bob replied: Thanks',
      );
      expect(
        _sentence(_n('4', type: NotificationType.reply, message: '')),
        'bob replied to you',
      );
    });

    test('unknown types show the stored message after the name', () {
      final s = NotificationTexts.sentence(
        _n('1', type: NotificationType.other, message: 'did something'),
      );
      expect(s.before, isEmpty);
      expect(s.after, ' did something');
    });

    test('titles follow the type', () {
      expect(
        NotificationType.values.map(
          (t) => t.localizedTitle(lookupAppLocalizations(const Locale('en'))),
        ),
        [for (final t in NotificationType.values) t.title],
      );
    });

    test('relative times, then the date', () {
      final now = DateTime(2026, 10, 16, 12);
      String at(Duration ago) => NotificationTexts.time(now.subtract(ago), now);
      expect(at(const Duration(seconds: 30)), 'Just now');
      expect(at(const Duration(minutes: 1)), '1m ago');
      expect(at(const Duration(minutes: 59)), '59m ago');
      expect(at(const Duration(hours: 2)), '2h ago');
      expect(at(const Duration(days: 1)), '1d ago');
      expect(at(const Duration(days: 6, hours: 23)), '6d ago');
      expect(at(const Duration(days: 7)), '9/10/2026');
    });
  });

  testWidgets('a notification shows the name in bold and the sentence', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ProfileImageCache(FakeImageStorageRepository()),
        child: testApp(
          home: Scaffold(
            body: NotificationItem(
              notification: _n('1', type: NotificationType.capsule),
              isSelected: false,
              selectionMode: false,
              onTap: () {},
              onLongPress: () {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('bob created a new capsule', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Just now'), findsOneWidget);
  });

  testWidgets('the selection bar shows the count and labels its buttons', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        home: Scaffold(
          body: NotificationSelectionActionBar(
            count: 3,
            onCancel: () {},
            onDelete: () {},
            onMarkAsRead: () {},
          ),
        ),
      ),
    );

    expect(find.text('3'), findsOneWidget);
    expect(find.text('selected'), findsOneWidget);
    expect(find.bySemanticsLabel('Mark as read'), findsOneWidget);
    expect(find.bySemanticsLabel('Delete'), findsOneWidget);
    expect(find.bySemanticsLabel('Cancel'), findsOneWidget);
    handle.dispose();
  });
}

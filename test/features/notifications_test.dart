import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/app_notification.dart';
import 'package:later/data/services/push_messaging_service.dart';
import 'package:later/features/notifications/notifications_store.dart';

import '../fakes/fake_repositories.dart';

AppNotification _n(String id, {bool read = false}) => AppNotification(
  id: id,
  type: NotificationType.follow,
  fromUserName: 'bob',
  message: 'started following you',
  isRead: read,
  fromUserId: 'bob-uid',
);

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

      expect(NotificationTap.fromData({}).type, NotificationType.other);
      expect(NotificationTap.fromData({'userId': ''}).userId, isNull);
    });

    test('builds a tap from an in-app notification', () {
      final tap = NotificationTap.fromNotification(_n('x'));
      expect(tap.type, NotificationType.follow);
      expect(tap.userId, 'bob-uid');
    });
  });
}

// The notifications tab (B6): days, the team's announcements, swipes and
// friend requests answered in place.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/app_notification.dart';
import 'package:later/data/models/social.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/models/user_settings.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:later/features/friends/friends_store.dart';
import 'package:later/features/notifications/notifications_selection_controller.dart';
import 'package:later/features/notifications/notifications_store.dart';
import 'package:later/features/notifications/widgets/notifications_list.dart';
import 'package:later/features/settings/settings_store.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

AppNotification _n(
  String id,
  DateTime at, {
  NotificationType type = NotificationType.follow,
  String from = 'bob',
}) => AppNotification(
  id: id,
  type: type,
  fromUserName: from,
  message: '',
  isRead: false,
  fromUserId: from,
  timestamp: at,
);

void main() {
  late FakeNotificationRepository notes;
  late FakeSocialRepository social;
  late FakeSettingsRepository settingsRepo;
  late FakeFriendsRepository friendsRepo;
  late FakeUserRepository users;

  setUp(() {
    notes = FakeNotificationRepository();
    social = FakeSocialRepository();
    settingsRepo = FakeSettingsRepository();
    friendsRepo = FakeFriendsRepository();
    users = FakeUserRepository()
      ..put(const UserProfile(uid: 'me', name: 'Me', username: 'me'))
      ..put(const UserProfile(uid: 'bob', name: 'Bob', username: 'bob'))
      ..put(const UserProfile(uid: 'zoe', name: 'Zoe', username: 'zoe'));
  });

  Future<void> pump(WidgetTester tester) async {
    final store = NotificationsStore(notes)..attach('me');
    final settings = SettingsStore(settingsRepo, utcOffsetMinutes: () => 0)
      ..attach('me');
    final friends = FriendsStore(
      friends: friendsRepo,
      users: users,
      notifications: notes,
    )..attach('me');
    addTearDown(() {
      store.dispose();
      friends.dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: store),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: friends),
          Provider<SocialRepository>.value(value: social),
          ChangeNotifierProvider(create: (_) => UserDirectory(users)),
          ChangeNotifierProvider(
            create: (_) => ProfileImageCache(FakeImageStorageRepository()),
          ),
        ],
        child: testApp(
          home: Scaffold(
            body: NotificationsList(
              filter: NotificationFilter.all,
              selection: NotificationsSelectionController(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('days, newest first, with the team\'s announcements', (
    tester,
  ) async {
    final now = DateTime.now();
    notes.put('me', [
      _n('a', now),
      _n('b', now.subtract(const Duration(days: 3))),
    ]);
    social.announcements = [
      Announcement(
        id: 'news',
        title: const {'en': 'New maps'},
        body: const {'en': 'Look around'},
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
    await pump(tester);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('From the Later team'), findsOneWidget);
    expect(find.text('New maps'), findsOneWidget);
    final today = tester.getTopLeft(find.text('Today')).dy;
    final yesterday = tester.getTopLeft(find.text('Yesterday')).dy;
    expect(today, lessThan(yesterday));
  });

  testWidgets('News off: no announcements', (tester) async {
    settingsRepo.docs['me'] = const UserSettings(
      notifications: NotificationSettings(news: false),
    );
    notes.put('me', [_n('a', DateTime.now())]);
    social.announcements = [
      Announcement(
        id: 'news',
        title: const {'en': 'New maps'},
        body: const {'en': 'Look around'},
        createdAt: DateTime.now(),
      ),
    ];
    await pump(tester);
    expect(find.text('New maps'), findsNothing);
  });

  testWidgets('a swipe right marks read, left deletes', (tester) async {
    final now = DateTime.now();
    notes.put('me', [_n('a', now), _n('b', now, from: 'zoe')]);
    await pump(tester);
    await tester.drag(
      find.textContaining('bob started', findRichText: true),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();
    expect(notes.calls, contains('markRead:a'));
    expect(notes.byUser['me']!.length, 2, reason: 'still there, read');

    await tester.drag(
      find.textContaining('zoe started', findRichText: true),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(notes.calls, contains('delete:b'));
  });

  testWidgets('a friend request is accepted in place', (tester) async {
    await friendsRepo.sendRequest(from: 'zoe', to: 'me');
    notes.put('me', [
      _n(
        'r',
        DateTime.now(),
        type: NotificationType.friendRequest,
        from: 'zoe',
      ),
    ]);
    await pump(tester);
    expect(find.text('Accept'), findsOneWidget);
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();
    expect(friendsRepo.calls, contains('accept:zoe->me'));
    // The accepting batch also adds the friend to both lists (the fake
    // leaves that to the test).
    users.put(
      const UserProfile(
        uid: 'me',
        name: 'Me',
        username: 'me',
        friends: ['zoe'],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('You are friends now'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}

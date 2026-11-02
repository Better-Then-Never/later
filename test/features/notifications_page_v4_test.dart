// The notifications page of Profile v4: filter pills, the friend requests
// card, Today and Earlier, unread rows, Follow back.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/data/models/app_notification.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:later/features/friends/friends_store.dart';
import 'package:later/features/notifications/notification_groups.dart';
import 'package:later/features/notifications/notifications_page.dart';
import 'package:later/features/notifications/notifications_selection_controller.dart';
import 'package:later/features/notifications/notifications_store.dart';
import 'package:later/features/notifications/widgets/notification_item.dart';
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
  bool read = true,
}) => AppNotification(
  id: id,
  type: type,
  fromUserName: from,
  message: '',
  isRead: read,
  fromUserId: from,
  timestamp: at,
);

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  group('NotificationFilter', () {
    test('every kind belongs to Friends, Capsules or Places', () {
      NotificationFilter? of(NotificationType t) => NotificationFilter.of(t);
      expect(of(NotificationType.follow), NotificationFilter.friends);
      expect(of(NotificationType.friendRequest), NotificationFilter.friends);
      expect(of(NotificationType.friendAccepted), NotificationFilter.friends);
      expect(of(NotificationType.reaction), NotificationFilter.capsules);
      expect(of(NotificationType.comment), NotificationFilter.capsules);
      expect(of(NotificationType.coAuthor), NotificationFilter.capsules);
      expect(of(NotificationType.capsuleOpen), NotificationFilter.capsules);
      expect(of(NotificationType.capsuleReady), NotificationFilter.places);
      expect(of(NotificationType.capsuleNearby), NotificationFilter.places);
      expect(of(NotificationType.achievement), isNull);
      final now = DateTime.now();
      final achievement = _n('a', now, type: NotificationType.achievement);
      expect(NotificationFilter.all.accepts(achievement), isTrue);
      expect(NotificationFilter.friends.accepts(achievement), isFalse);
    });
  });

  group('NotificationDay', () {
    test('today by the calendar, the rest earlier', () {
      final now = DateTime(2026, 11, 2, 9);
      expect(
        NotificationDay.of(DateTime(2026, 11, 2), now),
        NotificationDay.today,
      );
      expect(
        NotificationDay.of(DateTime(2026, 11, 1, 23, 59), now),
        NotificationDay.earlier,
      );
      expect(NotificationDay.of(null, now), NotificationDay.today);
    });
  });

  group('friendRequestNames', () {
    test('one, two, then first names and how many more', () {
      expect(friendRequestNames(['Dave Miller'], _en), 'Dave Miller');
      expect(
        friendRequestNames(['Dave Miller', 'Erin Moss'], _en),
        'Dave Miller and Erin Moss',
      );
      expect(
        friendRequestNames(['Dave Miller', 'Erin Moss', 'A', 'B', 'C'], _en),
        'Dave, Erin and 3 more',
      );
      expect(friendRequestNames(['', ''], _en), isNull);
      expect(friendRequestNames(['Dave Miller', ''], _en), 'Dave Miller');
    });
  });

  late FakeNotificationRepository notes;
  late FakeFriendsRepository friendsRepo;
  late FakeUserRepository users;

  setUp(() {
    notes = FakeNotificationRepository();
    friendsRepo = FakeFriendsRepository();
    users = FakeUserRepository()
      ..put(const UserProfile(uid: 'me', name: 'Me', username: 'me'))
      ..put(const UserProfile(uid: 'bob', name: 'Bob', username: 'bob'))
      ..put(
        const UserProfile(uid: 'dave', name: 'Dave Miller', username: 'dave'),
      )
      ..put(const UserProfile(uid: 'erin', name: 'Erin Moss', username: 'erin'))
      ..put(const UserProfile(uid: 'finn', name: 'Finn Lee', username: 'finn'))
      ..put(const UserProfile(uid: 'gus', name: 'Gus Vale', username: 'gus'));
  });

  Future<void> pump(WidgetTester tester, Widget home) async {
    final store = NotificationsStore(notes)..attach('me');
    final settings = SettingsStore(
      FakeSettingsRepository(),
      utcOffsetMinutes: () => 0,
    )..attach('me');
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
          Provider<SocialRepository>.value(value: FakeSocialRepository()),
          ChangeNotifierProvider(create: (_) => UserDirectory(users)),
          ChangeNotifierProvider(
            create: (_) => ProfileImageCache(FakeImageStorageRepository()),
          ),
        ],
        child: testApp(home: home),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the pills filter by kind; All shows everything', (tester) async {
    final now = DateTime.now();
    notes.put('me', [
      _n('f', now),
      _n('c', now, type: NotificationType.reaction, from: 'erin'),
      _n('p', now, type: NotificationType.capsuleReady, from: 'dave'),
    ]);
    await pump(tester, const NotificationsPage());
    expect(find.text('Notifications'), findsOneWidget);
    for (final pill in ['All', 'Friends', 'Capsules', 'Places']) {
      expect(find.text(pill), findsOneWidget);
    }
    Finder row(String text) => find.textContaining(text, findRichText: true);
    expect(row('bob started following'), findsOneWidget);
    expect(row('erin reacted'), findsOneWidget);
    expect(row('is ready'), findsOneWidget);

    await tester.tap(find.text('Capsules'));
    await tester.pumpAndSettle();
    expect(row('bob started following'), findsNothing);
    expect(row('erin reacted'), findsOneWidget);
    expect(row('is ready'), findsNothing);

    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    expect(row('is ready'), findsOneWidget);
    expect(row('erin reacted'), findsNothing);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(row('bob started following'), findsOneWidget);
    expect(row('is ready'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(row('erin reacted'), findsOneWidget);
    expect(row('bob started following'), findsOneWidget);
  });

  testWidgets('an empty filter says what will appear there', (tester) async {
    notes.put('me', [_n('f', DateTime.now())]);
    await pump(tester, const NotificationsPage());
    await tester.tap(find.text('Places'));
    await tester.pumpAndSettle();
    expect(
      find.text('Capsules waiting for you at their places will appear here'),
      findsOneWidget,
    );
  });

  testWidgets('today above earlier, each row in its group', (tester) async {
    final now = DateTime.now();
    notes.put('me', [
      _n('old', now.subtract(const Duration(days: 2)), from: 'erin'),
      _n('new', now),
    ]);
    await pump(tester, const NotificationsPage());
    final today = tester.getTopLeft(find.text('TODAY')).dy;
    final earlier = tester.getTopLeft(find.text('EARLIER')).dy;
    final fresh = tester
        .getTopLeft(find.textContaining('bob started', findRichText: true))
        .dy;
    final old = tester
        .getTopLeft(find.textContaining('erin started', findRichText: true))
        .dy;
    expect(today, lessThan(fresh));
    expect(fresh, lessThan(earlier));
    expect(earlier, lessThan(old));
  });

  testWidgets('only today: no Earlier label', (tester) async {
    notes.put('me', [_n('new', DateTime.now())]);
    await pump(tester, const NotificationsPage());
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('EARLIER'), findsNothing);
  });

  testWidgets('waiting requests: one card with the count and the names', (
    tester,
  ) async {
    await friendsRepo.sendRequest(from: 'dave', to: 'me');
    await friendsRepo.sendRequest(from: 'erin', to: 'me');
    var opened = 0;
    await pump(
      tester,
      Scaffold(
        body: NotificationsList(
          filter: NotificationFilter.all,
          selection: NotificationsSelectionController(),
          onOpenRequests: () => opened++,
        ),
      ),
    );
    expect(find.text('2 friend requests'), findsOneWidget);
    expect(find.text('Dave Miller and Erin Moss'), findsOneWidget);
    // The red count.
    expect(find.text('2'), findsOneWidget);
    await tester.tap(find.text('2 friend requests'));
    expect(opened, 1);

    await friendsRepo.sendRequest(from: 'finn', to: 'me');
    await friendsRepo.sendRequest(from: 'gus', to: 'me');
    await tester.pumpAndSettle();
    expect(find.text('4 friend requests'), findsOneWidget);
    expect(find.text('Dave, Erin and 2 more'), findsOneWidget);
  });

  testWidgets('the requests card: on All and Friends, not on Capsules', (
    tester,
  ) async {
    await friendsRepo.sendRequest(from: 'dave', to: 'me');
    await pump(tester, const NotificationsPage());
    expect(find.text('1 friend request'), findsOneWidget);
    expect(find.text('Dave Miller'), findsOneWidget);
    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(find.text('1 friend request'), findsOneWidget);
    await tester.tap(find.text('Capsules'));
    await tester.pumpAndSettle();
    expect(find.text('1 friend request'), findsNothing);
  });

  testWidgets('no requests: no card', (tester) async {
    notes.put('me', [_n('f', DateTime.now())]);
    await pump(tester, const NotificationsPage());
    expect(find.textContaining('friend request'), findsNothing);
  });

  testWidgets('unread rows are tinted; read rows are not', (tester) async {
    final now = DateTime.now();
    notes.put('me', [_n('u', now, read: false), _n('r', now, from: 'erin')]);
    await pump(tester, const NotificationsPage());
    Color? tint(String text) {
      final material = find.ancestor(
        of: find.textContaining(text, findRichText: true),
        matching: find.descendant(
          of: find.byType(NotificationItem),
          matching: find.byType(Material),
        ),
      );
      return tester.widget<Material>(material.first).color;
    }

    expect(tint('bob started'), AppPalette.light.unreadHighlight);
    expect(tint('erin started'), Colors.transparent);
  });

  testWidgets('Follow back follows them from the row', (tester) async {
    notes.put('me', [_n('f', DateTime.now())]);
    await pump(tester, const NotificationsPage());
    expect(find.text('Follow back'), findsOneWidget);
    await tester.tap(find.text('Follow back'));
    await tester.pumpAndSettle();
    expect(friendsRepo.following, contains('me>bob'));
    expect(find.text('Follow back'), findsNothing);
    expect(find.text('Following'), findsOneWidget);
  });

  testWidgets('no Follow back when already following', (tester) async {
    friendsRepo.following.add('me>bob');
    notes.put('me', [_n('f', DateTime.now())]);
    await pump(tester, const NotificationsPage());
    expect(find.text('Follow back'), findsNothing);
  });
}

// Profile v4 friends pages (Figma page 14): My friends, the Pin a friend
// sheet, Add friends and a friend's menu, with the stores on fakes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/models/user_settings.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:later/features/friends/friends_store.dart';
import 'package:later/features/friends/pages/add_friends_page.dart';
import 'package:later/features/friends/pages/my_friends_page.dart';
import 'package:later/features/friends/pinned_friends_controller.dart';
import 'package:later/features/friends/widgets/friend_options_modal.dart';
import 'package:later/features/friends/widgets/pin_friends_sheet.dart';
import 'package:later/features/profile/widgets/profile_friends_card.dart';
import 'package:later/features/settings/settings_store.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:later/shared/widgets/app_sheets.dart';
import 'package:later/shared/widgets/user/user_round_avatar.dart';
import 'package:later/shared/widgets/user/user_stamp.dart';
import 'package:later/shared/widgets/v2/card_v2.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

UserProfile _p(
  String uid,
  String name, {
  String? username,
  List<String> friends = const [],
}) => UserProfile(
  uid: uid,
  name: name,
  username: username ?? uid,
  friends: friends,
);

void main() {
  late FakeUserRepository users;
  late FakeFriendsRepository friendsRepo;
  late FakeSettingsRepository settingsRepo;
  late FriendsStore friends;
  late SettingsStore settings;

  setUp(() {
    users = FakeUserRepository()
      ..put(_p('me', 'Me', friends: ['ben', 'bob', 'carol', 'dave']))
      ..put(_p('ben', 'Ben Fischer', username: 'benf'))
      ..put(_p('bob', 'Bob Stone', username: 'bobstone'))
      ..put(_p('carol', 'Carol King', username: 'carolk'))
      ..put(_p('dave', 'Dave Miller', username: 'davem'));
    friendsRepo = FakeFriendsRepository();
    settingsRepo = FakeSettingsRepository();
  });

  /// Pumps [home] with the stores; [pins] are the pinned friends.
  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    List<String> pins = const [],
  }) async {
    // Still empty states and sheets: pumpAndSettle can settle.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    settingsRepo.docs['me'] = UserSettings(pinnedFriends: pins);
    settings = SettingsStore(settingsRepo, utcOffsetMinutes: () => 0)
      ..attach('me');
    friends = FriendsStore(
      friends: friendsRepo,
      users: users,
      notifications: FakeNotificationRepository(),
    )..attach('me');
    addTearDown(friends.dispose);
    tester.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: friends),
          ChangeNotifierProvider.value(value: settings),
          Provider<UserRepository>.value(value: users),
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

  /// Lets the toasts go away on their own.
  Future<void> drainToasts(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  double left(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text).first).dx;

  group('My friends', () {
    testWidgets('pinned row in order with a Pin slot, A to Z, a count', (
      tester,
    ) async {
      await pump(tester, const MyFriendsPage(), pins: ['carol', 'bob']);

      expect(find.text('My friends'), findsOneWidget);
      expect(find.text('PINNED ON YOUR PROFILE'), findsOneWidget);
      // First names under the pinned stamps, in the pin order.
      expect(find.text('Carol'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(left(tester, 'Carol'), lessThan(left(tester, 'Bob')));
      // Two of three: room for one more.
      expect(find.text('Pin'), findsOneWidget);

      for (final letter in ['B', 'C', 'D']) {
        expect(find.widgetWithText(GroupLabelV2, letter), findsOneWidget);
      }
      expect(find.text('Ben Fischer'), findsOneWidget);
      expect(find.text('@benf'), findsOneWidget);
      final ben = tester.getTopLeft(find.text('Ben Fischer')).dy;
      final bob = tester.getTopLeft(find.text('Bob Stone')).dy;
      final dave = tester.getTopLeft(find.text('Dave Miller')).dy;
      expect(ben, lessThan(bob));
      expect(bob, lessThan(dave));
      expect(find.byType(UserRoundAvatar), findsNothing);
      expect(find.byType(UserStamp), findsNWidgets(6));
      expect(find.text('4 friends'), findsOneWidget);
    });

    testWidgets('a full row has no Pin slot; a search hides the row', (
      tester,
    ) async {
      await pump(tester, const MyFriendsPage(), pins: ['carol', 'bob', 'dave']);
      expect(find.text('Pin'), findsNothing);

      await tester.enterText(find.byType(TextField), 'dav');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('PINNED ON YOUR PROFILE'), findsNothing);
      expect(find.text('Dave Miller'), findsOneWidget);
      expect(find.text('Ben Fischer'), findsNothing);
    });

    testWidgets('Edit opens Pin a friend and Done saves the pins', (
      tester,
    ) async {
      await pump(tester, const MyFriendsPage(), pins: ['carol']);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(find.text('Pin to your profile'), findsOneWidget);
      expect(find.text('1 of 3 pinned'), findsOneWidget);

      await tester.tap(find.text('Ben').last);
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(settingsRepo.docs['me']!.pinnedFriends, ['carol', 'ben']);
      await drainToasts(tester);
    });

    testWidgets('the dots open the friend\'s menu', (tester) async {
      await pump(tester, const MyFriendsPage());
      await tester.tap(find.bySemanticsLabel('More for Dave Miller'));
      await tester.pumpAndSettle();
      expect(find.text('Remove friend'), findsOneWidget);
      expect(find.text('Pin to my profile'), findsOneWidget);
    });

    testWidgets('no friends: the empty state', (tester) async {
      users.put(_p('me', 'Me'));
      await pump(tester, const MyFriendsPage());
      expect(find.text('No friends added yet'), findsOneWidget);
      expect(find.text('PINNED ON YOUR PROFILE'), findsNothing);
    });
  });

  group('Pin a friend', () {
    late List<String>? result;

    Widget opener() => Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          result = await showEdgeSheet<List<String>>(
            context,
            (_) => const PinFriendsSheet(
              pinned: ['carol', 'bob'],
              friends: ['ben', 'bob', 'carol', 'dave'],
            ),
          );
        },
        child: const Text('open'),
      ),
    );

    String? badgeOf(WidgetTester tester, String uid) {
      final texts = find.descendant(
        of: find.byKey(ValueKey(uid)),
        matching: find.byType(Text),
      );
      for (final e in texts.evaluate()) {
        final data = (e.widget as Text).data ?? '';
        if (int.tryParse(data) != null) return data;
      }
      return null;
    }

    testWidgets('toggles pins, numbers them in order, keeps the limit', (
      tester,
    ) async {
      result = null;
      await pump(tester, opener());
      // The directory knows the names (the real flow resolves them first).
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('2 of 3 pinned'), findsOneWidget);
      expect(badgeOf(tester, 'carol'), '1');
      expect(badgeOf(tester, 'bob'), '2');
      expect(badgeOf(tester, 'ben'), isNull);
      // Pinned first, in their order.
      expect(left(tester, 'Carol'), lessThan(left(tester, 'Bob')));

      await tester.tap(find.text('Ben'));
      await tester.pump();
      expect(find.text('3 of 3 pinned'), findsOneWidget);
      expect(badgeOf(tester, 'ben'), '3');

      // Over the limit: the message, nothing pinned.
      await tester.tap(find.text('Dave'));
      await tester.pump();
      expect(find.text('Up to 3 pinned friends'), findsOneWidget);
      expect(badgeOf(tester, 'dave'), isNull);
      await drainToasts(tester);

      // Unpinning the first moves the others up.
      await tester.tap(find.text('Carol'));
      await tester.pump();
      expect(badgeOf(tester, 'carol'), isNull);
      expect(badgeOf(tester, 'bob'), '1');
      expect(badgeOf(tester, 'ben'), '2');

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(result, ['bob', 'ben']);
    });

    testWidgets('the search narrows the grid', (tester) async {
      await pump(tester, opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'car');
      await tester.pump();
      expect(find.text('Carol'), findsOneWidget);
      expect(find.text('Dave'), findsNothing);
    });
  });

  group('Add friends', () {
    setUp(() {
      users
        ..put(_p('me', 'Me', friends: ['bob']))
        ..put(_p('bob', 'Bob Stone', friends: ['me', 'frank', 'hugo']))
        ..put(_p('erin', 'Erin Moss', username: 'erinm', friends: ['bob']))
        ..put(_p('frank', 'Frank Ocean', username: 'franko'))
        ..put(_p('hugo', 'Hugo Laurent'));
    });

    testWidgets('Requests: accept or not now; the ones sent can be cancelled', (
      tester,
    ) async {
      await friendsRepo.sendRequest(from: 'erin', to: 'me');
      await friendsRepo.sendRequest(from: 'me', to: 'hugo');
      friendsRepo.calls.clear();
      await pump(tester, const AddFriendsPage());

      expect(find.text('Add friends'), findsOneWidget);
      expect(find.text('Share your Later card'), findsOneWidget);
      expect(find.text("Scan a friend's code"), findsOneWidget);
      expect(find.text('Requests (1)'), findsOneWidget);
      expect(find.text('ASKED TO BE YOUR FRIEND'), findsOneWidget);
      expect(find.text('Erin Moss'), findsOneWidget);
      expect(find.text('@erinm · 1 mutual friend'), findsOneWidget);
      expect(find.text('SENT BY YOU'), findsOneWidget);
      expect(find.text('Hugo Laurent'), findsOneWidget);

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();
      expect(friendsRepo.calls, ['accept:erin->me']);
      await drainToasts(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(friendsRepo.calls.last, 'cancel:me->hugo');
      await drainToasts(tester);
    });

    testWidgets('Not now declines', (tester) async {
      await friendsRepo.sendRequest(from: 'erin', to: 'me');
      friendsRepo.calls.clear();
      await pump(tester, const AddFriendsPage());
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();
      expect(friendsRepo.calls, ['reject:erin->me']);
      await drainToasts(tester);
    });

    testWidgets('Suggested: + Add, or Requested once sent', (tester) async {
      await friendsRepo.sendRequest(from: 'me', to: 'hugo');
      friendsRepo.calls.clear();
      await pump(tester, const AddFriendsPage());

      // No requests: Suggested comes first.
      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('PEOPLE YOU MAY KNOW'), findsOneWidget);
      expect(find.text('Frank Ocean'), findsOneWidget);
      expect(find.text('@franko · 1 mutual friend'), findsOneWidget);
      expect(find.text('Requested'), findsOneWidget);

      await tester.tap(find.text('+ Add'));
      await tester.pumpAndSettle();
      expect(friendsRepo.calls, ['send:me->frank']);
      await drainToasts(tester);

      await tester.tap(find.text('Requests'));
      await tester.pumpAndSettle();
      expect(find.text('No friend requests'), findsOneWidget);
      expect(find.text('Frank Ocean'), findsOneWidget, reason: 'sent');
    });

    testWidgets('a search shows the people found instead of the tabs', (
      tester,
    ) async {
      await pump(tester, const AddFriendsPage());
      await tester.enterText(find.byType(TextField), 'fra');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('FOUND'), findsOneWidget);
      expect(find.text('Frank Ocean'), findsOneWidget);
      expect(find.text('Share your Later card'), findsNothing);
    });
  });

  group("A friend's menu", () {
    Widget opener() => Builder(
      builder: (context) => TextButton(
        onPressed: () =>
            FriendOptionsModal.show(context, 'bob', leavePage: false),
        child: const Text('open'),
      ),
    );

    testWidgets('their stamp and the rows; Block and Report in red', (
      tester,
    ) async {
      await pump(tester, opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Bob Stone'), findsOneWidget);
      expect(find.text('@bobstone'), findsOneWidget);
      expect(find.byType(UserStamp), findsOneWidget);
      expect(find.textContaining('Friends since'), findsNothing);
      final rows = [
        'Pin to my profile',
        "Share Bob's card",
        "Notifications about Bob's capsules",
        'Remove friend',
        'Block',
        'Report',
      ];
      for (final (i, row) in rows.indexed) {
        expect(find.text(row), findsOneWidget);
        if (i > 0) {
          expect(
            tester.getTopLeft(find.text(rows[i - 1])).dy,
            lessThan(tester.getTopLeft(find.text(row)).dy),
          );
        }
      }
      final block = tester.widget<Text>(find.text('Block'));
      final remove = tester.widget<Text>(find.text('Remove friend'));
      expect(block.style!.color, isNot(remove.style!.color));
    });

    testWidgets('pins and unpins the friend', (tester) async {
      await pump(tester, opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pin to my profile'));
      await tester.pumpAndSettle();
      expect(settingsRepo.docs['me']!.pinnedFriends, ['bob']);
      expect(find.text('Bob Stone pinned'), findsOneWidget);
      await drainToasts(tester);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Unpin from my profile'), findsOneWidget);
      await tester.tap(find.text('Unpin from my profile'));
      await tester.pumpAndSettle();
      expect(settingsRepo.docs['me']!.pinnedFriends, isEmpty);
      await drainToasts(tester);
    });

    testWidgets('the switch follows them', (tester) async {
      await pump(tester, opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(friendsRepo.following, {'me>bob'});
      await drainToasts(tester);
    });

    testWidgets('Remove friend asks first and keeps the list open', (
      tester,
    ) async {
      await pump(tester, opener());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove friend'));
      await tester.pumpAndSettle();
      expect(
        find.text('Are you sure you want to remove user from friends?'),
        findsOneWidget,
      );
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(friendsRepo.calls, ['remove:me-bob']);
      expect(find.text('open'), findsOneWidget);
    });
  });

  testWidgets('the profile card shows stamps, not round avatars', (
    tester,
  ) async {
    await pump(
      tester,
      Builder(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => PinnedFriendsController(
            friends: context.read<FriendsStore>(),
            settings: context.read<SettingsStore>(),
          ),
          child: const Scaffold(body: ProfileFriendsCard()),
        ),
      ),
      pins: ['dave'],
    );
    expect(find.byType(UserStamp), findsNWidgets(4));
    expect(find.byType(UserRoundAvatar), findsNothing);
    expect(find.text('Dave'), findsOneWidget);
    // Four friends, five places: the dashed Pin slot opens the sheet.
    expect(find.text('My friends'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Choose pinned friends'));
    await tester.pumpAndSettle();
    expect(find.text('Pin to your profile'), findsOneWidget);
    expect(find.text('1 of 3 pinned'), findsOneWidget);
  });
}

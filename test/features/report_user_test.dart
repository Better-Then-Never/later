// The profile menu's "Report" asks why and files a report on the profile.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/data/models/social.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/features/friends/friends_store.dart';
import 'package:later/features/friends/pages/add_friend_profile_page.dart';
import 'package:later/features/friends/widgets/report_user.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

class _Session extends ChangeNotifier implements SessionController {
  @override
  String? get uid => 'me';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('reporting a profile asks why and files it', (tester) async {
    final social = FakeSocialRepository();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionController>.value(value: _Session()),
          Provider<SocialRepository>.value(value: social),
        ],
        child: testApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => reportUser(context, 'bob'),
              child: const Text('report'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    expect(social.reports.single['targetPath'], 'users/bob');
    expect(social.reports.single['target'], ReportTarget.user);
    expect(social.reports.single['reason'], ReportReason.spam);
    // The thank-you toast goes away on its own.
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets("a stranger's profile has Report and Block; your own has none", (
    tester,
  ) async {
    final social = FakeSocialRepository();
    final users = FakeUserRepository()
      ..put(const UserProfile(uid: 'me', name: 'Me', username: 'me'))
      ..put(const UserProfile(uid: 'leo', name: 'Leo', username: 'leo'));
    final friends = FriendsStore(
      friends: FakeFriendsRepository(),
      users: users,
      notifications: FakeNotificationRepository(),
    )..attach('me');
    addTearDown(friends.dispose);
    Future<void> open(String uid) => tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionController>.value(value: _Session()),
          Provider<SocialRepository>.value(value: social),
          ChangeNotifierProvider.value(value: friends),
          ChangeNotifierProvider(create: (_) => UserDirectory(users)),
          ChangeNotifierProvider(
            create: (_) => ProfileImageCache(
              FakeImageStorageRepository(),
              evict: (_) async {},
            ),
          ),
        ],
        child: testApp(
          home: AddFriendProfilePage(key: ValueKey(uid), userId: uid),
        ),
      ),
    );
    await open('leo');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Show menu'));
    await tester.pumpAndSettle();
    expect(find.text('Block'), findsOneWidget);
    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    expect(social.reports.single['targetPath'], 'users/leo');
    await tester.pump(const Duration(seconds: 5));

    await open('me');
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Show menu'), findsNothing);
  });
}

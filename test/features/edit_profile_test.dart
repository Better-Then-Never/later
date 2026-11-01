import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:later/features/profile/edit_profile_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeUserRepository users;
  late SessionController session;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    auth = FakeAuthRepository();
    users = FakeUserRepository();
    users.profiles['u1'] = const UserProfile(
      uid: 'u1',
      name: 'Alice Walker',
      username: 'alice',
      about: 'Collecting small moments',
    );
  });

  Future<void> pumpPage(WidgetTester tester) async {
    // A phone-sized screen, so every row is on it.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Signed in first: the page is only built for a signed-in user.
    auth.emit('u1');
    // Created in the test's zone, so its stream events arrive on pump.
    session = SessionController(auth: auth, users: users)..start();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
    expect(session.uid, 'u1');
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionController>.value(value: session),
          Provider<UserRepository>.value(value: users),
          Provider<ImageStorageRepository>(
            create: (_) => FakeImageStorageRepository(),
          ),
          ChangeNotifierProvider(
            create: (_) => ProfileImageCache(FakeImageStorageRepository()),
          ),
          Provider(create: (_) => PreferencesStore()),
        ],
        child: testApp(home: const EditProfilePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the live postcard and the rows', (tester) async {
    await pumpPage(tester);
    expect(find.text('Edit profile'), findsOneWidget);
    // The postcard and the Name row.
    expect(find.text('Alice Walker'), findsNWidgets(2));
    expect(find.text('Collecting small moments'), findsWidgets);
    expect(find.text('Home town'), findsOneWidget);
    await tester.ensureVisible(find.text('Classic · White'));
    await tester.pumpAndSettle();
    expect(find.text('Classic · White'), findsOneWidget);
  });

  testWidgets('the stamp sheet saves a new shape and colour', (tester) async {
    await pumpPage(tester);
    await tester.ensureVisible(find.text('Classic · White'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Classic · White'));
    await tester.pumpAndSettle();
    expect(find.text('Your stamp'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('stamp-shape-round')));
    await tester.tap(find.byKey(const ValueKey('stamp-colour-blue')));
    await tester.pump();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    final stamp = users.profiles['u1']!.stamp;
    expect(stamp.shape, StampShape.round);
    expect(stamp.color.value, 'blue');
  });

  testWidgets('the home town is saved, and cleared when emptied', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Home town'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '  Kraków ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(users.profiles['u1']!.homeTown, 'Kraków');
  });
}

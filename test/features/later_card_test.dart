import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:later/features/profile/share/share_profile_page.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('the card turns over: words, code and address on the back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final auth = FakeAuthRepository()..emit('u1');
    final users = FakeUserRepository();
    users.profiles['u1'] = const UserProfile(
      uid: 'u1',
      name: 'Alice Walker',
      username: 'alice',
      about: 'Collecting small moments',
      homeTown: 'Warszawa',
    );
    final session = SessionController(auth: auth, users: users)..start();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 10));
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
        ],
        child: testApp(home: const ShareProfilePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your Later card'), findsOneWidget);
    expect(find.text('Tap the card to turn it over'), findsOneWidget);
    expect(find.text('Scan to add me on Later'), findsNothing);

    await tester.tap(find.byType(LaterCardFront));
    await tester.pumpAndSettle();
    expect(find.byType(LaterCardBack), findsOneWidget);
    expect(find.text('Scan to add me on Later'), findsOneWidget);
    expect(find.text('Collecting small moments\n— Alice'), findsOneWidget);
    expect(find.text('@alice'), findsOneWidget);
    expect(find.text('WARSZAWA'), findsOneWidget);
    expect(find.text('Tap to turn it back'), findsOneWidget);

    await tester.tap(find.byType(LaterCardBack));
    await tester.pumpAndSettle();
    expect(find.byType(LaterCardFront), findsOneWidget);
  });
}

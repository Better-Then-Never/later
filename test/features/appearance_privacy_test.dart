import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/appearance/appearance_controller.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/core/theme/app_theme.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/settings/pages/appearance_settings_page.dart';
import 'package:later/features/settings/pages/privacy_settings_page.dart';
import 'package:later/features/settings/settings_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

void main() {
  late AppearanceController appearance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesStore();
    await prefs.init();
    appearance = AppearanceController(prefs);
    await appearance.load();
  });

  Widget appearanceApp(Widget home) =>
      ChangeNotifierProvider<AppearanceController>.value(
        value: appearance,
        child: testApp(home: home, theme: AppTheme.light),
      );

  group('AppearanceSettingsPage', () {
    testWidgets('theme and size apply and are remembered', (tester) async {
      await tester.pumpWidget(appearanceApp(const AppearanceSettingsPage()));
      expect(find.text('Same as phone'), findsOneWidget);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(appearance.themeMode, ThemeMode.dark);

      await tester.tap(find.text('Large'));
      await tester.pumpAndSettle();
      expect(appearance.uiSize, UiSize.large);

      // A fresh controller reads the same choices back.
      await tester.runAsync(() async {
        final prefs = PreferencesStore();
        await prefs.init();
        final again = AppearanceController(prefs);
        await again.load();
        expect(again.themeMode, ThemeMode.dark);
        expect(again.uiSize, UiSize.large);
      });
    });
  });

  group('LanguageSettingsPage', () {
    testWidgets('lists the languages in their own names', (tester) async {
      await tester.pumpWidget(appearanceApp(const LanguageSettingsPage()));
      for (final name in AppearanceController.languageNames.values) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text("Phone's language"), findsOneWidget);

      await tester.tap(find.text('Polski'));
      await tester.pumpAndSettle();
      expect(appearance.language, 'pl');
      expect(appearance.locale, const Locale('pl'));

      await tester.tap(find.text("Phone's language"));
      await tester.pumpAndSettle();
      expect(appearance.language, isNull);
    });
  });

  group('PrivacySettingsPage', () {
    testWidgets('defaults for new capsules and read receipts save', (
      tester,
    ) async {
      final repo = FakeSettingsRepository();
      final store = SettingsStore(repo, utcOffsetMinutes: () => 0)
        ..attach('alice');
      final auth = FakeAuthRepository();
      final users = FakeUserRepository()
        ..put(const UserProfile(uid: 'alice', name: 'Alice', username: 'al'));
      final session = SessionController(auth: auth, users: users, scoped: []);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsStore>.value(value: store),
            ChangeNotifierProvider<SessionController>.value(value: session),
          ],
          child: testApp(home: const PrivacySettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Everyone on the map'), findsOneWidget);
      await tester.tap(find.text('Friends'));
      await tester.pumpAndSettle();
      expect(
        repo.docs['alice']!.privacy.defaultVisibility,
        CapsulePrivacy.friends,
      );

      await tester.tap(find.text('Approximate location'));
      await tester.pumpAndSettle();
      expect(
        repo.docs['alice']!.privacy.locationPrecision,
        LocationPrecision.approximate,
      );

      await tester.scrollUntilVisible(find.text('Read receipts'), 100);
      await tester.ensureVisible(find.text('Read receipts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Read receipts'));
      await tester.pumpAndSettle();
      expect(repo.docs['alice']!.privacy.readReceipts, isFalse);
      store.detach();
    });
  });
}

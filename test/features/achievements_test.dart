import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/data/models/social.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/features/achievements/achievement_catalog.dart';
import 'package:later/features/achievements/achievement_mark.dart';
import 'package:later/features/achievements/achievement_sheet.dart';
import 'package:later/features/achievements/achievements_view.dart';
import 'package:later/features/achievements/streak_flame.dart';
import 'package:provider/provider.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';
import 'package:later/core/config/feature_flags.dart';

UserProfile _profile({UserStats stats = const UserStats(), int friends = 0}) =>
    UserProfile(
      uid: 'me',
      name: 'Me',
      username: 'me',
      friends: [for (var i = 0; i < friends; i++) 'f$i'],
      stats: stats,
    );

void main() {
  test('the catalog matches the server registry (ids and tiers)', () {
    // functions/lib/gamification.js ACHIEVEMENTS
    const server = {
      'first_capsule': [1],
      'collector': [5, 25, 100, 500],
      'open_book': [1, 10, 50],
      'animator': [1, 10],
      'streak': [3, 7, 14, 30, 100],
      'explorer': [3, 10, 25, 100],
      'traveler': [100, 1000, 10000],
      'crowd_pleaser': [10, 100, 1000],
      'chatterbox': [1, 25, 100],
      'friendly': [1, 10, 50],
      'night_owl': [1, 10],
      'early_bird': [1, 10],
      'curious': [10, 50, 250, 1000],
    };
    expect({for (final a in AchievementCatalog.all) a.id: a.tiers}, server);
  });

  test('standing: the higher of the server level and the stats', () {
    final standings = AchievementStanding.of(
      _profile(stats: const UserStats(capsules: 30), friends: 2),
      const [UnlockedAchievement(id: 'friendly', tier: 1, tiers: 3)],
    );
    AchievementStanding of(String id) =>
        standings.firstWhere((s) => s.def.id == id);
    expect(of('first_capsule').tier, 0);
    expect(of('first_capsule').complete, isTrue);
    expect(of('collector').tier, 1, reason: '30 >= 25');
    expect(of('collector').nextGoal, 100);
    expect(of('friendly').tier, 1, reason: 'the server already said level 2');
    expect(of('open_book').unlocked, isFalse);
    // The Animator follows loop capsules (FeatureFlags).
    expect(
      standings.any((s) => s.def.id == 'animator'),
      FeatureFlags.loopCapsules,
    );
  });

  test('a streak shows only while it can still go on', () {
    final now = DateTime.now();
    String day(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final yesterday = UserStats(
      streakCurrent: 5,
      streakLastDay: day(now.subtract(const Duration(days: 1))),
    );
    expect(yesterday.streakAt(now), 5);
    expect(yesterday.extendedToday(now), isFalse);
  });

  test('every achievement has a group; the progress is toward the next '
      'level', () {
    final groups = {for (final a in AchievementCatalog.all) a.id: a.group};
    expect(groups['explorer'], AchievementGroup.places);
    expect(groups['streak'], AchievementGroup.habits);
    expect(groups['friendly'], AchievementGroup.friends);
    expect(groups['first_capsule'], AchievementGroup.capsules);

    final standings = AchievementStanding.of(
      _profile(stats: const UserStats(capsules: 20)),
      const [],
    );
    AchievementStanding of(String id) =>
        standings.firstWhere((s) => s.def.id == id);
    expect(of('collector').progress, 0.8, reason: '20 of 25');
    expect(of('first_capsule').progress, 1);
    expect(of('explorer').started, isFalse);
    expect(of('explorer').progress, 0);
  });

  test('the sheet writes progress in the app language', () {
    final en = lookupAppLocalizations(const Locale('en'));
    expect(AchievementSheet.progressText(en, 16, 20), '16 of 20 · 4 to go');
    expect(
      AchievementSheet.progressText(en, 1234.7, 10000),
      '1,234 of 10,000 · 8,766 to go',
    );
    final de = lookupAppLocalizations(const Locale('de'));
    expect(
      AchievementSheet.progressText(de, 1234, 10000),
      '1.234 von 10.000 · noch 8.766',
    );
  });

  Future<void> pumpPage(
    WidgetTester tester,
    UserProfile profile, {
    SessionController? session,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SocialRepository>.value(value: FakeSocialRepository()),
          if (session != null)
            ChangeNotifierProvider<SessionController>.value(value: session),
        ],
        child: testApp(home: AchievementsPage(profile: profile)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the page groups the whole catalogue into marks', (tester) async {
    await pumpPage(
      tester,
      _profile(stats: const UserStats(capsules: 20, places: 4)),
    );
    expect(find.text('Achievements'), findsOneWidget);
    final total = AchievementCatalog.visible.length;
    // First capsule, Collector (5), Explorer (3).
    expect(find.text('3 of $total'), findsOneWidget);
    expect(find.text('CAPSULES'), findsOneWidget);
    expect(find.text('HABITS'), findsOneWidget);
    expect(find.text('PLACES'), findsOneWidget);
    expect(find.text('FRIENDS'), findsOneWidget);
    expect(find.byType(AchievementTile), findsNWidgets(total));
    expect(find.text('Done'), findsOneWidget, reason: 'first capsule');
    expect(find.text('Level 1 · 80 %'), findsOneWidget, reason: '20 of 25');
    expect(find.text('Level 1 · 40 %'), findsOneWidget, reason: '4 of 10');
    expect(find.text('Not started'), findsWidgets);
    // A friend's page: no streak row, no Passport button.
    expect(find.byType(StreakFlame), findsNothing);

    await tester.tap(find.text('Explorer'));
    await tester.pumpAndSettle();
    expect(find.byType(AchievementSheet), findsOneWidget);
    expect(find.text('4 of 10 · 6 to go'), findsOneWidget);
    expect(find.text('Level 1 of 4'), findsOneWidget);
    expect(find.text('See your countries in the Passport'), findsNothing);
  });

  testWidgets('your own page: the streak on top, the Passport from a place', (
    tester,
  ) async {
    final me = _profile(stats: const UserStats(capsules: 2, places: 4));
    final auth = FakeAuthRepository()..emit('me');
    final users = FakeUserRepository()..put(me);
    final session = SessionController(auth: auth, users: users)..start();
    addTearDown(session.dispose);
    await pumpPage(tester, me, session: session);
    expect(find.text('No streak yet'), findsOneWidget);
    expect(find.text('Make a capsule today to start a streak'), findsOneWidget);

    await tester.tap(find.text('Explorer'));
    await tester.pumpAndSettle();
    expect(find.text('See your countries in the Passport'), findsOneWidget);
  });
}

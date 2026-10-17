import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/social.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/features/achievements/achievement_catalog.dart';
import 'package:later/features/achievements/achievements_view.dart';
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

  testWidgets('the page lists every achievement with its next goal', (
    tester,
  ) async {
    final social = FakeSocialRepository();
    await tester.pumpWidget(
      Provider<SocialRepository>.value(
        value: social,
        child: testApp(
          home: AchievementsPage(
            profile: _profile(stats: const UserStats(capsules: 7)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Achievements'), findsWidgets);
    expect(find.text('First capsule'), findsOneWidget);
    expect(find.text('Collector'), findsOneWidget);
    expect(find.text('Level 1 of 4'), findsOneWidget, reason: '7 capsules');
    expect(find.text('Create 25 capsules'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Early bird'), 200);
    expect(find.text('Early bird'), findsOneWidget);
  });
}

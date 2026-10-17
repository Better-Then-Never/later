// Unlock and streak moments (B7): celebrated once, from real events, and the
// streak on the map with its at-risk variant.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/data/models/social.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/achievements/moment_toast.dart';
import 'package:later/features/achievements/moments.dart';
import 'package:later/features/achievements/streak_pill.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

class _Session extends ChangeNotifier implements SessionController {
  @override
  String? uid = 'me';

  @override
  UserProfile? profile = const UserProfile(
    uid: 'me',
    name: 'Me',
    username: 'me',
  );

  void stats(UserStats stats) {
    profile = UserProfile(uid: 'me', name: 'Me', username: 'me', stats: stats);
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _day(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

UnlockedAchievement _a(String id, int tier, int tiers, [int minutes = 0]) =>
    UnlockedAchievement(
      id: id,
      tier: tier,
      tiers: tiers,
      unlockedAt: DateTime(2026, 10, 17, 12, minutes),
    );

void main() {
  late FakeSocialRepository social;
  late _Session session;
  late List<Moment> shown;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    social = FakeSocialRepository();
    session = _Session();
    shown = [];
  });

  MomentsController controller() => MomentsController(
    session: session,
    social: social,
    prefs: PreferencesStore(),
    show: shown.add,
    settle: Duration.zero,
  )..start();

  test(
    'the first start takes what is there as seen; new levels show',
    () async {
      social.achievements['me'] = [_a('first_capsule', 0, 1)];
      final c = controller();
      await pumpEventQueue();
      expect(shown, isEmpty, reason: 'old news on the first start');

      social.achievements['me'] = [
        _a('first_capsule', 0, 1),
        _a('collector', 0, 4, 1),
      ];
      social.changed();
      await pumpEventQueue();
      final moment = shown.single as AchievementMoment;
      expect(moment.def.id, 'collector');
      expect(moment.more, 0);
      c.dispose();
    },
  );

  test('a catch-up shows the newest and counts the rest', () async {
    social.achievements['me'] = [];
    final c = controller();
    await pumpEventQueue();
    social.achievements['me'] = [
      _a('collector', 1, 4, 1),
      _a('explorer', 0, 4, 5),
      _a('chatterbox', 0, 3, 2),
    ];
    social.changed();
    await pumpEventQueue();
    final moment = shown.single as AchievementMoment;
    expect(moment.def.id, 'explorer');
    expect(moment.more, 2);
    c.dispose();
  });

  test(
    'levels stored one by one (a server catch-up) become one moment',
    () async {
      social.achievements['me'] = [];
      final c = controller();
      await pumpEventQueue();
      social.achievements['me'] = [_a('collector', 1, 4, 1)];
      social.changed();
      social.achievements['me'] = [
        _a('collector', 1, 4, 1),
        _a('friendly', 2, 3, 3),
      ];
      social.changed();
      await pumpEventQueue();
      final moment = shown.single as AchievementMoment;
      expect(moment.def.id, 'friendly');
      expect(moment.more, 1);
      c.dispose();
    },
  );

  test('seen levels survive a restart; unlocks while closed show', () async {
    social.achievements['me'] = [_a('collector', 0, 4)];
    final first = controller();
    await pumpEventQueue();
    first.dispose();

    // Closed; the server unlocked level 2 meanwhile.
    social.achievements['me'] = [_a('collector', 1, 4)];
    final second = controller();
    await pumpEventQueue();
    expect((shown.single as AchievementMoment).tier, 1);
    second.dispose();

    final third = controller();
    await pumpEventQueue();
    expect(shown, hasLength(1), reason: 'not twice');
    third.dispose();
  });

  test('a streak milestone shows once; other days do not', () async {
    final today = _day(DateTime.now());
    final c = controller();
    await pumpEventQueue();
    session.stats(UserStats(streakCurrent: 6, streakLastDay: today));
    await pumpEventQueue();
    expect(shown, isEmpty);
    session.stats(UserStats(streakCurrent: 7, streakLastDay: today));
    await pumpEventQueue();
    expect((shown.single as StreakMoment).days, 7);
    session.stats(UserStats(streakCurrent: 7, streakLastDay: today));
    await pumpEventQueue();
    expect(shown, hasLength(1));
    c.dispose();
  });

  Future<void> pumpPill(WidgetTester tester, UserStats stats) async {
    session.stats(stats);
    await tester.pumpWidget(
      ChangeNotifierProvider<SessionController>.value(
        value: session,
        child: testApp(
          home: const Scaffold(body: Center(child: StreakPill())),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the pill: hidden without a streak', (tester) async {
    await pumpPill(tester, const UserStats());
    expect(find.text('🔥'), findsNothing);
  });

  testWidgets('the pill at risk opens a card with the way to the camera', (
    tester,
  ) async {
    final yesterday = _day(DateTime.now().subtract(const Duration(days: 1)));
    await pumpPill(
      tester,
      UserStats(streakCurrent: 4, streakLongest: 9, streakLastDay: yesterday),
    );
    expect(find.text('4'), findsOneWidget);
    expect(find.byType(ColorFiltered), findsOneWidget, reason: 'grey flame');
    await tester.tap(find.byType(StreakPill));
    await tester.pumpAndSettle();
    expect(find.text('4-day streak'), findsOneWidget);
    expect(find.textContaining("Today isn't counted yet"), findsOneWidget);
    expect(find.text('Longest: 9 days'), findsOneWidget);
    expect(find.text('Make a capsule'), findsOneWidget);
  });

  testWidgets('the pill once today counts: in colour, no camera', (
    tester,
  ) async {
    await pumpPill(
      tester,
      UserStats(streakCurrent: 5, streakLastDay: _day(DateTime.now())),
    );
    expect(find.byType(ColorFiltered), findsNothing);
    await tester.tap(find.byType(StreakPill));
    await tester.pumpAndSettle();
    expect(find.text('Today counts. See you tomorrow!'), findsOneWidget);
    expect(find.text('Make a capsule'), findsNothing);
  });

  testWidgets('the unlock card drops in, then leaves by itself', (
    tester,
  ) async {
    final overlayKey = GlobalKey<OverlayState>();
    MomentToast.overlay = () => overlayKey.currentState;
    addTearDown(MomentToast.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<SessionController>.value(
        value: session,
        child: testApp(
          home: Overlay(
            key: overlayKey,
            initialEntries: [
              OverlayEntry(builder: (_) => const SizedBox.expand()),
            ],
          ),
        ),
      ),
    );
    social.achievements['me'] = [];
    final c = MomentsController(
      session: session,
      social: social,
      prefs: PreferencesStore(),
      show: MomentToast.show,
      settle: Duration.zero,
    )..start();
    await tester.pump();
    social.achievements['me'] = [_a('collector', 1, 4)];
    social.changed();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Achievement unlocked'), findsOneWidget);
    expect(find.text('Collector'), findsOneWidget);
    expect(find.text('Level 2 of 4'), findsOneWidget);
    await tester.pump(MomentToast.stay);
    await tester.pumpAndSettle();
    expect(find.text('Achievement unlocked'), findsNothing);
    c.dispose();
  });
}

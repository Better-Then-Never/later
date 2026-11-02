import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/models/user_settings.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/history/own_capsules_store.dart';
import 'package:later/features/settings/device_settings_store.dart';
import 'package:later/features/settings/settings_store.dart';
import 'package:later/features/streak/streak_calendar.dart';
import 'package:later/features/streak/streak_page.dart';
import 'package:later/features/streak/streak_reminder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

Capsule _capsule(String id, DateTime at, {String owner = 'me'}) => Capsule(
  id: id,
  ownerId: owner,
  title: id,
  privacy: CapsulePrivacy.friends,
  color: CapsuleColor.green,
  createdAt: at,
);

/// Records what would reach the phone's notifications.
class _FakeScheduler implements StreakReminderScheduler {
  final List<(DateTime, String)> scheduled = [];
  int cancels = 0;

  @override
  Future<void> schedule(
    DateTime at, {
    required String title,
    required String body,
    required NotificationSettings settings,
  }) async => scheduled.add((at, body));

  @override
  Future<void> cancel() async => cancels++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreakCalendar', () {
    test('the week runs Monday to Sunday around today', () {
      // Wednesday 4 Nov 2026.
      final week = StreakCalendar.weekOf(DateTime(2026, 11, 4, 15, 30));
      expect(week.first, DateTime(2026, 11, 2));
      expect(week.last, DateTime(2026, 11, 8));
      expect(week.map((d) => d.weekday), [1, 2, 3, 4, 5, 6, 7]);
      // A Sunday belongs to the week before.
      expect(
        StreakCalendar.weekOf(DateTime(2026, 11, 8)).first,
        DateTime(2026, 11, 2),
      );
      // Across a month's end.
      expect(
        StreakCalendar.weekOf(DateTime(2026, 12, 1)).first,
        DateTime(2026, 11, 30),
      );
    });

    test('the month starts on its weekday and fills whole weeks', () {
      // 1 Nov 2026 is a Sunday: six empty places before it.
      final cells = StreakCalendar.monthGrid(DateTime(2026, 11, 20));
      expect(cells.take(6), everyElement(isNull));
      expect(cells[6], DateTime(2026, 11, 1));
      expect(cells.whereType<DateTime>().length, 30);
      expect(cells.length % 7, 0);
      // February 2027 starts on a Monday.
      final feb = StreakCalendar.monthGrid(DateTime(2027, 2));
      expect(feb.first, DateTime(2027, 2, 1));
      expect(feb.whereType<DateTime>().length, 28);
    });

    test('days with a capsule: the streak and the own capsules', () {
      const stats = UserStats(streakCurrent: 3, streakLastDay: '2026-11-02');
      final days = StreakCalendar.capsuleDays(
        stats,
        ownerId: 'me',
        capsules: [
          _capsule('a', DateTime(2026, 10, 20, 9)),
          _capsule('b', DateTime(2026, 10, 21, 9), owner: 'friend'),
        ],
      );
      expect(days, {
        DateTime(2026, 11, 2),
        DateTime(2026, 11, 1),
        DateTime(2026, 10, 31),
        DateTime(2026, 10, 20),
      });
    });

    test('today counts from the server or from a capsule taken today', () {
      final now = DateTime(2026, 11, 2, 18);
      expect(
        StreakCalendar.todayDone(
          const UserStats(streakCurrent: 1, streakLastDay: '2026-11-02'),
          now,
        ),
        isTrue,
      );
      expect(StreakCalendar.todayDone(const UserStats(), now), isFalse);
      expect(
        StreakCalendar.todayDone(
          const UserStats(),
          now,
          ownerId: 'me',
          capsules: [_capsule('a', DateTime(2026, 11, 2, 7))],
        ),
        isTrue,
      );
      expect(
        StreakCalendar.todayDone(
          const UserStats(),
          now,
          ownerId: 'me',
          capsules: [_capsule('a', DateTime(2026, 11, 2, 7), owner: 'bob')],
        ),
        isFalse,
        reason: 'a capsule made with a friend is theirs',
      );
    });

    test('hours left today, rounded up', () {
      expect(StreakCalendar.hoursLeft(DateTime(2026, 11, 2, 15, 10)), 9);
      expect(StreakCalendar.hoursLeft(DateTime(2026, 11, 2, 23, 30)), 1);
      expect(StreakCalendar.hoursLeft(DateTime(2026, 11, 2)), 24);
    });

    test('reads the server day', () {
      expect(StreakCalendar.parseDay('2026-11-02'), DateTime(2026, 11, 2));
      expect(StreakCalendar.parseDay('soon'), isNull);
      expect(StreakCalendar.parseDay(null), isNull);
    });
  });

  group('StreakReminder.next', () {
    const at20 = 20 * 60;

    test('off: none', () {
      expect(
        StreakReminder.next(
          now: DateTime(2026, 11, 2, 10),
          on: false,
          minutes: at20,
          todayDone: false,
          streak: 4,
        ),
        isNull,
      );
    });

    test('today not counted yet, before the time: today', () {
      expect(
        StreakReminder.next(
          now: DateTime(2026, 11, 2, 10),
          on: true,
          minutes: at20,
          todayDone: false,
          streak: 4,
        ),
        (at: DateTime(2026, 11, 2, 20), days: 4),
      );
    });

    test('today counted: tomorrow, the streak still alive', () {
      expect(
        StreakReminder.next(
          now: DateTime(2026, 11, 2, 10),
          on: true,
          minutes: at20,
          todayDone: true,
          streak: 5,
        ),
        (at: DateTime(2026, 11, 3, 20), days: 5),
      );
    });

    test('past the time without a capsule: tomorrow, a new streak', () {
      expect(
        StreakReminder.next(
          now: DateTime(2026, 11, 2, 21),
          on: true,
          minutes: at20,
          todayDone: false,
          streak: 4,
        ),
        (at: DateTime(2026, 11, 3, 20), days: 0),
      );
    });

    test('across the month and year ends, at the chosen time', () {
      expect(
        StreakReminder.next(
          now: DateTime(2026, 12, 31, 22),
          on: true,
          minutes: 8 * 60 + 30,
          todayDone: true,
          streak: 2,
        )!.at,
        DateTime(2027, 1, 1, 8, 30),
      );
    });

    test('the words speak of the streak or of starting one', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      final keep = StreakReminder.texts(l10n, (at: DateTime(2026), days: 4));
      expect(keep.$1, 'Keep your streak');
      expect(keep.$2, contains('4-day streak'));
      final start = StreakReminder.texts(l10n, (at: DateTime(2026), days: 0));
      expect(start.$2, 'Make a capsule today to start a streak');
    });
  });

  group('StreakReminderSync', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      StreakReminder.debugSupported = true;
    });
    tearDown(() => StreakReminder.debugSupported = null);

    test(
      'schedules when on, moves on after a capsule, cancels when off',
      () async {
        final now = DateTime(2026, 11, 2, 10);
        final auth = FakeAuthRepository()..emit('me');
        final users = FakeUserRepository()
          ..put(
            const UserProfile(
              uid: 'me',
              name: 'Me',
              username: 'me',
              stats: UserStats(streakCurrent: 4, streakLastDay: '2026-11-01'),
            ),
          );
        final capsules = FakeCapsuleRepository();
        final device = DeviceSettingsStore(PreferencesStore());
        final settings = SettingsStore(
          FakeSettingsRepository(),
          utcOffsetMinutes: () => 0,
        );
        final own = OwnCapsulesStore(capsules);
        final session = SessionController(
          auth: auth,
          users: users,
          scoped: [device, settings, own],
        )..start();
        final scheduler = _FakeScheduler();
        final sync = StreakReminderSync(
          session: session,
          device: device,
          settings: settings,
          own: own,
          scheduler: scheduler,
          clock: () => now,
        )..start();
        addTearDown(() {
          sync.dispose();
          session.dispose();
        });
        await pumpEventQueue();
        expect(scheduler.scheduled, isEmpty, reason: 'off by default');

        await device.setStreakReminder(true);
        await pumpEventQueue();
        expect(scheduler.scheduled.last.$1, DateTime(2026, 11, 2, 20));
        expect(scheduler.scheduled.last.$2, contains('4-day streak'));

        // A capsule today: tomorrow's reminder instead.
        capsules.emitOwn([_capsule('new', DateTime(2026, 11, 2, 9))]);
        await pumpEventQueue();
        expect(scheduler.scheduled.last.$1, DateTime(2026, 11, 3, 20));

        // Nothing new: nothing scheduled again.
        final count = scheduler.scheduled.length;
        sync.update();
        await pumpEventQueue();
        expect(scheduler.scheduled.length, count);

        await device.setStreakReminderMinutes(21 * 60 + 15);
        await pumpEventQueue();
        expect(scheduler.scheduled.last.$1, DateTime(2026, 11, 3, 21, 15));

        final cancels = scheduler.cancels;
        await device.setStreakReminder(false);
        await pumpEventQueue();
        expect(scheduler.cancels, cancels + 1);
      },
    );
  });

  group('StreakPage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      StreakReminder.debugSupported = true;
    });
    tearDown(() => StreakReminder.debugSupported = null);

    Future<(DeviceSettingsStore, FakeSettingsRepository)> pump(
      WidgetTester tester, {
      required UserStats stats,
      List<Capsule> capsules = const [],
      required DateTime now,
    }) async {
      final auth = FakeAuthRepository()..emit('me');
      final users = FakeUserRepository()
        ..put(UserProfile(uid: 'me', name: 'Me', username: 'me', stats: stats));
      final repo = FakeCapsuleRepository()..own = capsules;
      final device = DeviceSettingsStore(PreferencesStore());
      final settingsRepo = FakeSettingsRepository();
      final settings = SettingsStore(settingsRepo, utcOffsetMinutes: () => 0);
      final own = OwnCapsulesStore(repo);
      final session = SessionController(
        auth: auth,
        users: users,
        scoped: [device, settings, own],
      )..start();
      addTearDown(session.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SessionController>.value(value: session),
            ChangeNotifierProvider<DeviceSettingsStore>.value(value: device),
            ChangeNotifierProvider<SettingsStore>.value(value: settings),
            ChangeNotifierProvider<OwnCapsulesStore>.value(value: own),
          ],
          child: testApp(home: StreakPage(clock: () => now)),
        ),
      );
      await tester.pumpAndSettle();
      return (device, settingsRepo);
    }

    testWidgets('at risk: the days, the hours left, the week and the best', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      // Wednesday 4 Nov 2026, 15:10; capsules Mon and Tue.
      await pump(
        tester,
        stats: const UserStats(
          streakCurrent: 4,
          streakLongest: 12,
          streakLastDay: '2026-11-03',
        ),
        now: DateTime(2026, 11, 4, 15, 10),
      );
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('4 days'), findsOneWidget);
      expect(
        find.text('Make a capsule today to keep it. 9 hours left.'),
        findsOneWidget,
      );
      expect(find.text('THIS WEEK'), findsOneWidget);
      expect(find.text('NOVEMBER 2026'), findsOneWidget);
      // Week: Mon and Tue filled, today (Wed) dashed and empty.
      final week = tester
          .widgetList<StreakDay>(
            find.byWidgetPredicate((w) => w is StreakDay && w.label == null),
          )
          .toList();
      expect(week.map((d) => d.filled), [
        true,
        true,
        false,
        false,
        false,
        false,
        false,
      ]);
      expect(week[2].today, isTrue);
      // Month: 31 Oct is out of it; 1 to 3 Nov are in.
      StreakDay month(String n) => tester.widget<StreakDay>(
        find.byWidgetPredicate((w) => w is StreakDay && w.label == n),
      );
      expect(month('1').filled, isTrue);
      expect(month('3').filled, isTrue);
      expect(month('4').filled, isFalse);
      expect(find.text('Best streak'), findsOneWidget);
      expect(find.text('12 days'), findsOneWidget);
      expect(find.text('Remind me at 8:00 PM'), findsOneWidget);
      expect(find.text('Make a capsule'), findsOneWidget);
    });

    testWidgets('today counted by a capsule on its way; the reminder switch', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 2.6;
      addTearDown(tester.view.reset);
      final now = DateTime(2026, 11, 4, 15, 10);
      final (device, settingsRepo) = await pump(
        tester,
        stats: const UserStats(
          streakCurrent: 4,
          streakLongest: 4,
          streakLastDay: '2026-11-03',
        ),
        capsules: [_capsule('a', DateTime(2026, 11, 4, 8))],
        now: now,
      );
      expect(find.text('Today counts. See you tomorrow!'), findsOneWidget);
      expect(
        tester.widget<StreakDay>(find.byType(StreakDay).at(2)).filled,
        isTrue,
      );
      // The old server reminder was on: turning the phone's on ends it.
      await settingsRepo.saveNotifications(
        'me',
        const NotificationSettings(streakReminder: true),
      );
      await tester.pumpAndSettle();
      // The phone allows notifications.
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async => {Permission.notification.value: 1},
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          null,
        ),
      );
      await tester.ensureVisible(find.byType(Switch));
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(device.streakReminder, isTrue);
      expect(settingsRepo.docs['me']!.notifications.streakReminder, isFalse);
    });
  });
}

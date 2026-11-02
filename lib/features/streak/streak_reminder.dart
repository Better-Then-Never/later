import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../app/session/session_controller.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_settings.dart';
import '../../data/services/push_messaging_service.dart';
import '../history/own_capsules_store.dart';
import '../settings/device_settings_store.dart';
import '../settings/settings_store.dart';
import 'streak_calendar.dart';

/// The next streak reminder: when, and the streak it speaks of (0: "start
/// a streak").
typedef StreakReminderPlan = ({DateTime at, int days});

/// The streak reminder (owner, 2 Nov 2026): a notification this phone
/// schedules for itself at the chosen time (20:00 unless changed), skipped
/// on days a capsule already counts. No server push. One reminder is
/// scheduled at a time and planned again when the app starts or comes
/// back, when a capsule is made and when the setting changes.
abstract final class StreakReminder {
  /// The id of its notification.
  static const notificationId = 720300;

  /// Android only, like the place alerts (the app sends no iOS pushes).
  static bool get isSupported =>
      debugSupported ?? (!kIsWeb && Platform.isAndroid);

  /// Tests: pretend the phone can (or cannot) show it.
  @visibleForTesting
  static bool? debugSupported;

  /// The next reminder after [now] at [minutes] past midnight, or null when
  /// it is off. Today's when nothing counts today yet and its time is still
  /// to come; else tomorrow's. [streak] is the streak as of now (with today
  /// when today counts): tomorrow it is still alive only if today counts.
  static StreakReminderPlan? next({
    required DateTime now,
    required bool on,
    required int minutes,
    required bool todayDone,
    required int streak,
  }) {
    if (!on) return null;
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    if (!todayDone && now.isBefore(today)) return (at: today, days: streak);
    return (
      at: DateTime(now.year, now.month, now.day + 1, hour, minute),
      days: todayDone ? streak : 0,
    );
  }

  /// The words of [plan]'s notification.
  static (String, String) texts(AppLocalizations l10n, StreakReminderPlan p) =>
      p.days > 0
      ? (l10n.streakReminderKeepTitle, l10n.streakReminderKeepBody(p.days))
      : (l10n.streakReminderStartTitle, l10n.streakStartToday);
}

/// Shows the reminder at a time, or takes it back.
abstract interface class StreakReminderScheduler {
  Future<void> schedule(
    DateTime at, {
    required String title,
    required String body,
    required NotificationSettings settings,
  });

  Future<void> cancel();
}

/// [StreakReminderScheduler] with the phone's local notifications. Inexact
/// (no exact-alarm permission): Android may deliver it some minutes late
/// while the phone dozes.
class LocalStreakReminderScheduler implements StreakReminderScheduler {
  LocalStreakReminderScheduler(
    this._push, {
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Sets the plugin up (channels, the tap handler) before anything is
  /// scheduled; initialising it again here would replace its tap handler.
  final PushMessagingService _push;
  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> schedule(
    DateTime at, {
    required String title,
    required String body,
    required NotificationSettings settings,
  }) async {
    try {
      await _push.initialize();
      final channelId = !settings.sound
          ? 'activity_silent'
          : !settings.vibrate
          ? 'activity_novibrate'
          : 'activity';
      await _plugin.zonedSchedule(
        StreakReminder.notificationId,
        title,
        body,
        // An instant: the plan is already in local time.
        tz.TZDateTime.from(at.toUtc(), tz.UTC),
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            AppL10n.current.notificationsChannelActivity,
            icon: '@drawable/ic_stat_notification',
            color: AppColors.brandGreen,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: jsonEncode({'type': 'streak'}),
      );
    } catch (e, st) {
      AppLogger.warning(
        'Streak reminder not scheduled',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _plugin.cancel(StreakReminder.notificationId);
    } catch (e) {
      AppLogger.warning('Streak reminder not cancelled', error: e);
    }
  }
}

/// Keeps the scheduled reminder in step with the streak, the user's
/// capsules and the setting: plans it again whenever one of them changes,
/// and when the app comes back to the screen (a new day may have begun).
class StreakReminderSync with WidgetsBindingObserver {
  StreakReminderSync({
    required SessionController session,
    required DeviceSettingsStore device,
    required SettingsStore settings,
    required OwnCapsulesStore own,
    required StreakReminderScheduler scheduler,
    DateTime Function()? clock,
  }) : _session = session,
       _device = device,
       _settings = settings,
       _own = own,
       _scheduler = scheduler,
       _clock = clock ?? DateTime.now;

  final SessionController _session;
  final DeviceSettingsStore _device;
  final SettingsStore _settings;
  final OwnCapsulesStore _own;
  final StreakReminderScheduler _scheduler;
  final DateTime Function() _clock;

  bool _applied = false;
  Object? _last;
  Future<void> _queue = Future.value();

  void start() {
    _session.addListener(update);
    _device.addListener(update);
    _settings.addListener(update);
    _own.addListener(update);
    WidgetsBinding.instance.addObserver(this);
    update();
  }

  void dispose() {
    _session.removeListener(update);
    _device.removeListener(update);
    _settings.removeListener(update);
    _own.removeListener(update);
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) update();
  }

  /// Plans the reminder again; schedules only when the plan changed.
  @visibleForTesting
  void update() {
    if (!StreakReminder.isSupported) return;
    if (_session.status == SessionStatus.unknown) return;
    final uid = _session.uid;
    StreakReminderPlan? plan;
    if (uid != null) {
      final profile = _session.profile;
      // Wait for what decides it rather than cancel and schedule again.
      if (profile == null || !_device.isLoaded || !_settings.isLoaded) return;
      final now = _clock();
      plan = StreakReminder.next(
        now: now,
        on: _device.streakReminder && _settings.notifications.enabled,
        minutes: _device.streakReminderMinutes,
        todayDone: StreakCalendar.todayDone(
          profile.stats,
          now,
          capsules: _own.capsules,
          ownerId: uid,
        ),
        streak: profile.stats.streakAt(now),
      );
    }
    final n = _settings.notifications;
    // The words and the channel count too (the language, the sound).
    final key = (plan, AppL10n.current.localeName, n.sound, n.vibrate);
    if (_applied && key == _last) return;
    _applied = true;
    _last = key;
    _queue = _queue.then((_) => _apply(plan, n));
  }

  Future<void> _apply(StreakReminderPlan? plan, NotificationSettings n) async {
    if (plan == null) return _scheduler.cancel();
    final (title, body) = StreakReminder.texts(AppL10n.current, plan);
    AppLogger.info('Streak reminder: ${plan.at} (${plan.days} days)');
    await _scheduler.schedule(plan.at, title: title, body: body, settings: n);
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_page_route.dart';
import '../../app/router/app_routes.dart';
import '../../app/session/session_controller.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/capsule.dart';
import '../../data/models/user_profile.dart';
import '../../shared/widgets/buttons/default_green_button.dart';
import '../../shared/widgets/options/options_section.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/v2/card_v2.dart';
import '../achievements/streak_flame.dart';
import '../history/own_capsules_store.dart';
import '../settings/device_settings_store.dart';
import '../settings/settings_store.dart';
import 'streak_calendar.dart';
import 'streak_reminder.dart';
import 'streak_reminder_controls.dart';

/// The streak (Figma page 14, `7191:1271`): the flame and the days, the
/// hours left today; this week and this month with the days that had a
/// capsule; the best streak and the daily reminder; Make a capsule.
class StreakPage extends StatelessWidget {
  const StreakPage({super.key, this.clock});

  /// Tests: what time it is.
  final DateTime Function()? clock;

  static Future<void> open(BuildContext context) =>
      Navigator.of(context).push(appRoute<void>(const StreakPage()));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final now = clock?.call() ?? DateTime.now();
    final uid = context.select<SessionController?, String?>((s) => s?.uid);
    final stats =
        context.select<SessionController?, UserStats?>(
          (s) => s?.profile?.stats,
        ) ??
        const UserStats();
    final capsules = context.select<OwnCapsulesStore?, List<Capsule>>(
      (s) => s?.capsules ?? const [],
    );
    final days = StreakCalendar.capsuleDays(
      stats,
      capsules: capsules,
      ownerId: uid,
    );
    final done = StreakCalendar.todayDone(
      stats,
      now,
      capsules: capsules,
      ownerId: uid,
    );
    final streak = stats.streakAt(now);
    return Scaffold(
      backgroundColor: palette.backgroundAlt,
      body: Column(
        children: [
          PageHeaderV2(
            title: l10n.streakPageTitle,
            backLabel: l10n.commonBack,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                24 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [
                _Today(streak: streak, done: done, now: now),
                const SizedBox(height: 8),
                GroupLabelV2(l10n.streakThisWeek),
                _Week(now: now, days: days, done: done),
                const SizedBox(height: 8),
                GroupLabelV2(DateFormat.yMMMM(l10n.localeName).format(now)),
                _Month(now: now, days: days, done: done),
                const SizedBox(height: 16),
                _BestAndReminder(
                  longest: math.max(stats.streakLongest, streak),
                ),
                const SizedBox(height: 20),
                DefaultGreenButton(
                  text: l10n.streakMakeCapsule,
                  width: double.infinity,
                  height: 52,
                  textFontSize: 18,
                  onTap: () => unawaited(AppRoutes.toCamera(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The flame, "4 days", and what today needs.
class _Today extends StatelessWidget {
  const _Today({required this.streak, required this.done, required this.now});

  final int streak;
  final bool done;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final line = done
        ? l10n.streakSafe
        : streak > 0
        ? l10n.streakKeepHoursLeft(StreakCalendar.hoursLeft(now))
        : l10n.streakStartToday;
    return CardV2(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      child: Column(
        children: [
          StreakFlame(size: 48, greyed: !done),
          const SizedBox(height: 6),
          Text(
            l10n.streakDaysCount(streak),
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 34,
              height: 1.1,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            line,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              height: 1.3,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Monday to Sunday: a filled circle for a day with a capsule, a dashed
/// ring for today while it waits for one.
class _Week extends StatelessWidget {
  const _Week({required this.now, required this.days, required this.done});

  final DateTime now;
  final Set<DateTime> days;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final letters = MaterialLocalizations.of(context).narrowWeekdays;
    final today = StreakCalendar.dayOf(now);
    return CardV2(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 16),
      child: Row(
        children: [
          for (final day in StreakCalendar.weekOf(now))
            Expanded(
              child: Column(
                children: [
                  Text(
                    // narrowWeekdays starts on Sunday.
                    letters[day.weekday % 7],
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreakDay(
                    size: 36,
                    filled: days.contains(day) || (day == today && done),
                    today: day == today,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// The month: each day a circle, filled for a day with a capsule.
class _Month extends StatelessWidget {
  const _Month({required this.now, required this.days, required this.done});

  final DateTime now;
  final Set<DateTime> days;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final letters = MaterialLocalizations.of(context).narrowWeekdays;
    final today = StreakCalendar.dayOf(now);
    final cells = StreakCalendar.monthGrid(now);
    return CardV2(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 1; i <= 7; i++)
                Expanded(
                  child: Text(
                    letters[i % 7],
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12,
                      color: palette.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (var row = 0; row < cells.length; row += 7)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  for (final day in cells.sublist(row, row + 7))
                    Expanded(
                      child: Center(
                        child: day == null
                            ? const SizedBox(height: 32)
                            : StreakDay(
                                size: 32,
                                label: '${day.day}',
                                filled:
                                    days.contains(day) ||
                                    (day == today && done),
                                today: day == today,
                                muted: day.isAfter(today),
                              ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One day of the week or the month.
class StreakDay extends StatelessWidget {
  const StreakDay({
    super.key,
    required this.size,
    required this.filled,
    this.today = false,
    this.label,
    this.muted = false,
  });

  final double size;

  /// A capsule counts for this day.
  final bool filled;

  /// Today: a dashed green ring while nothing counts yet.
  final bool today;

  /// The day's number (the month).
  final String? label;

  /// A day still to come.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final words = label;
    final dashed = today && !filled;
    final Widget? number = words == null
        ? null
        : Text(
            words,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              height: 1,
              fontWeight: filled || today ? FontWeight.bold : FontWeight.normal,
              color: filled
                  ? AppColors.onAccent
                  : muted
                  ? palette.textFaint
                  : palette.textSecondary,
            ),
          );
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: dashed
            ? const _DashedRing(color: AppColors.brandGreen, stroke: 2)
            : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? AppColors.brandGreen
                : words == null
                ? null
                : palette.surfaceMuted,
            border: filled || dashed || words != null
                ? null
                : Border.all(color: palette.divider, width: 1.5),
          ),
          child: number == null ? null : Center(child: number),
        ),
      ),
    );
  }
}

class _DashedRing extends CustomPainter {
  const _DashedRing({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    const dashes = 12;
    const sweep = 2 * math.pi / dashes;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * sweep, sweep * 0.6, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRing old) =>
      old.color != color || old.stroke != stroke;
}

/// The best streak, and the daily reminder (this phone only).
class _BestAndReminder extends StatelessWidget {
  const _BestAndReminder({required this.longest});

  final int longest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final device = StreakReminder.isSupported
        ? context.watch<DeviceSettingsStore?>()
        : null;
    final pushesOn = context.select<SettingsStore?, bool>(
      (s) => s?.notifications.enabled ?? true,
    );
    return CardV2Rows(
      indent: 16,
      children: [
        RowV2(
          title: l10n.streakBest,
          value: l10n.streakDaysCount(longest),
          arrow: false,
        ),
        if (device != null)
          RowV2(
            title: l10n.streakRemindAt(
              StreakReminderControls.time(
                context,
                device.streakReminderMinutes,
              ),
            ),
            subtitle: pushesOn ? null : l10n.streakReminderPushOff,
            arrow: false,
            onTap: pushesOn
                ? () => StreakReminderControls.pickTime(context)
                : null,
            trailing: AppSwitch(
              compact: true,
              value: device.streakReminder,
              onChanged: pushesOn
                  ? (v) => StreakReminderControls.setOn(context, v)
                  : null,
            ),
          ),
      ],
    );
  }
}

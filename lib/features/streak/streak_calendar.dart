import '../../data/models/capsule.dart';
import '../../data/models/user_profile.dart';

/// The days of the Streak page, from what the app knows: the streak the
/// server keeps (its last day and length) and the user's own capsules on
/// this phone. Days are local midnights.
abstract final class StreakCalendar {
  /// [time]'s local day, at midnight.
  static DateTime dayOf(DateTime time) {
    final local = time.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// "2026-11-02" (the server's `streakLastDay`) as a day; null when
  /// unreadable.
  static DateTime? parseDay(String? key) {
    if (key == null) return null;
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  /// The days with a capsule: the streak's days (its last day and the
  /// days before it, as many as it is long) and the days of [ownerId]'s
  /// [capsules] (when taken, else when made). Capsules made with friends
  /// are someone else's and do not count, as on the server.
  static Set<DateTime> capsuleDays(
    UserStats stats, {
    Iterable<Capsule> capsules = const [],
    String? ownerId,
  }) {
    final days = <DateTime>{};
    final last = parseDay(stats.streakLastDay);
    if (last != null) {
      for (var i = 0; i < stats.streakCurrent; i++) {
        days.add(DateTime(last.year, last.month, last.day - i));
      }
    }
    for (final c in capsules) {
      if (ownerId != null && c.ownerId != ownerId) continue;
      final at = c.capturedAt ?? c.createdAt;
      if (at != null) days.add(dayOf(at));
    }
    return days;
  }

  /// Whether a capsule counts for today: the server says so, or one of the
  /// user's capsules was taken today (it may still be on its way).
  static bool todayDone(
    UserStats stats,
    DateTime now, {
    Iterable<Capsule> capsules = const [],
    String? ownerId,
  }) {
    if (stats.extendedToday(now)) return true;
    final today = dayOf(now);
    for (final c in capsules) {
      if (ownerId != null && c.ownerId != ownerId) continue;
      final at = c.capturedAt ?? c.createdAt;
      if (at != null && dayOf(at) == today) return true;
    }
    return false;
  }

  /// The week of [now], Monday to Sunday.
  static List<DateTime> weekOf(DateTime now) {
    final today = dayOf(now);
    final monday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - DateTime.monday),
    );
    return [
      for (var i = 0; i < 7; i++)
        DateTime(monday.year, monday.month, monday.day + i),
    ];
  }

  /// The month of [month] as calendar rows from Monday: null for the empty
  /// places before the first and after the last day.
  static List<DateTime?> monthGrid(DateTime month) {
    final first = DateTime(month.year, month.month);
    final length = DateTime(month.year, month.month + 1, 0).day;
    final before = first.weekday - DateTime.monday;
    final cells = <DateTime?>[
      for (var i = 0; i < before; i++) null,
      for (var d = 1; d <= length; d++) DateTime(month.year, month.month, d),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  /// Whole hours left of [now]'s day, rounded up (at 15:10, 9).
  static int hoursLeft(DateTime now) {
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final minutes = midnight.difference(now).inMinutes;
    return ((minutes + 59) ~/ 60).clamp(1, 24);
  }
}

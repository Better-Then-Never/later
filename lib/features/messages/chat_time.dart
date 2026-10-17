import 'package:intl/intl.dart';

/// Time labels of the chat screens (same wording as on main).
abstract final class ChatTime {
  /// Chat list: the time today ("14:05"), "Yesterday", the weekday within
  /// a week ("Monday"), then the date as on the app's date pills
  /// ("16.10.2026"). A pending server time counts as now.
  static String listLabel(DateTime? time, DateTime now) {
    final at = time ?? now;
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final daysAgo = today.difference(day).inDays;
    if (daysAgo <= 0) return messageTime(at);
    if (daysAgo == 1) return 'Yesterday';
    if (daysAgo < 7) return DateFormat('EEEE').format(at);
    return DateFormat('dd.MM.yyyy').format(at);
  }

  /// Day separator: "Today", "Yesterday", then "October 16, 2026". A
  /// message still waiting for its server time counts as today.
  static String dayLabel(DateTime? time, DateTime now) {
    if (time == null || isSameDay(time, now)) return 'Today';
    if (isSameDay(time, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat('MMMM d, yyyy').format(time);
  }

  /// Time inside a bubble: "14:05".
  static String messageTime(DateTime time) => DateFormat('HH:mm').format(time);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

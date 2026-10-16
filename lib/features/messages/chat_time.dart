import 'package:intl/intl.dart';

/// Time labels of the chat screens (same wording as on main).
abstract final class ChatTime {
  /// Chat list: "Now", "5m", "3h", "2d", then "16/10".
  static String listLabel(DateTime? time, DateTime now) {
    if (time == null) return '';
    final age = now.difference(time);
    if (age.inMinutes < 1) return 'Now';
    if (age.inHours < 1) return '${age.inMinutes}m';
    if (age.inDays < 1) return '${age.inHours}h';
    if (age.inDays < 7) return '${age.inDays}d';
    return '${time.day}/${time.month}';
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

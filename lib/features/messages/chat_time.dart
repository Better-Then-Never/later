import 'package:intl/intl.dart';

import '../../core/l10n/l10n.dart';
import '../../core/l10n/app_dates.dart';

/// Time labels of the chat screens, in the app's language. Widgets pass
/// `context.l10n`; without it the app-wide [AppL10n.current] is used.
abstract final class ChatTime {
  /// Chat list: the time today ("14:05"), "Yesterday", the weekday within
  /// a week ("Monday"), then the date as on the app's date pills
  /// ("16.10.2026"). A pending server time counts as now.
  static String listLabel(
    DateTime? time,
    DateTime now, {
    AppLocalizations? l10n,
  }) {
    final strings = l10n ?? AppL10n.current;
    final locale = strings.localeName;
    final at = time ?? now;
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final daysAgo = today.difference(day).inDays;
    if (daysAgo <= 0) return messageTime(at, locale: locale);
    if (daysAgo == 1) return strings.messagesYesterday;
    if (daysAgo < 7) {
      // Stand-alone weekday, capitalised as a label ("понедельник" ->
      // "Понедельник"); English is unchanged.
      final weekday = DateFormat('cccc', locale).format(at);
      return weekday.isEmpty
          ? weekday
          : weekday[0].toUpperCase() + weekday.substring(1);
    }
    return AppDates.short(at, locale);
  }

  /// Day separator: "Today", "Yesterday", then the full date ("October 16,
  /// 2026" in English). A message still waiting for its server time counts
  /// as today.
  static String dayLabel(
    DateTime? time,
    DateTime now, {
    AppLocalizations? l10n,
  }) {
    final strings = l10n ?? AppL10n.current;
    if (time == null || isSameDay(time, now)) return strings.messagesToday;
    if (isSameDay(time, now.subtract(const Duration(days: 1)))) {
      return strings.messagesYesterday;
    }
    return DateFormat.yMMMMd(strings.localeName).format(time);
  }

  /// Time inside a bubble: "14:05" (the locale's 24-hour form).
  static String messageTime(DateTime time, {String? locale}) =>
      DateFormat.Hm(locale ?? AppL10n.current.localeName).format(time);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

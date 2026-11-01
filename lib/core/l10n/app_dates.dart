import 'package:intl/intl.dart';

/// Dates as the app writes them. One short format everywhere (pills, cards,
/// lists, notifications): day.month.year with two digits, the original
/// design's green pills ("05.01.2026"). Long, worded dates (chat day
/// separators) stay with [DateFormat.yMMMMd].
abstract final class AppDates {
  static String short(DateTime date, String locale) =>
      DateFormat('dd.MM.yyyy', locale).format(date);

  /// A date inside a sentence ("Left 14 Jun 2025 · opened 14 Jun 2026"):
  /// the day, the short month and the year in the app's language.
  static String medium(DateTime date, String locale) =>
      DateFormat('d MMM y', locale).format(date);

  /// [medium] without the year when [date] is in [now]'s year ("22 Sep"),
  /// for the narrow map card.
  static String compact(DateTime date, String locale, DateTime now) =>
      date.year == now.year
      ? DateFormat('d MMM', locale).format(date)
      : medium(date, locale);
}

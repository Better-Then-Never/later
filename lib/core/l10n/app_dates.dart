import 'package:intl/intl.dart';

/// Dates as the app writes them. One short format everywhere (pills, cards,
/// lists, notifications): day.month.year with two digits, the original
/// design's green pills ("05.01.2026"). Long, worded dates (chat day
/// separators) stay with [DateFormat.yMMMMd].
abstract final class AppDates {
  static String short(DateTime date, String locale) =>
      DateFormat('dd.MM.yyyy', locale).format(date);
}

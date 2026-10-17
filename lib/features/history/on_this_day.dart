import '../../data/models/capsule.dart';

/// "On this day": the user's open capsules made on today's calendar date in
/// earlier years, the most recent year first. Uses the moment the photo was
/// taken when known (an offline capsule may arrive later).
abstract final class OnThisDay {
  static List<Capsule> from(Iterable<Capsule> capsules, DateTime now) {
    final found = capsules.where((c) {
      final at = _at(c);
      return at != null &&
          !c.pending &&
          at.year < now.year &&
          at.month == now.month &&
          at.day == now.day &&
          c.isOpen(now);
    }).toList()..sort((a, b) => _at(b)!.compareTo(_at(a)!));
    return found;
  }

  /// Whole years between [capsule] and [now] (1 or more for [from]'s list).
  static int yearsAgo(Capsule capsule, DateTime now) =>
      now.year - (_at(capsule)?.year ?? now.year);

  static DateTime? _at(Capsule c) => (c.capturedAt ?? c.createdAt)?.toLocal();
}

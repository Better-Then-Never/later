import '../../data/models/world.dart';

/// Passport stamps (capsule v3 E1, E2): one per town, the first time the
/// user leaves a capsule there. The towns are the ones the functions keep
/// in `users/{uid}/world/summary` (functions/lib/gamification.js), so a
/// stamp is never given for opening someone else's capsule, and it stays
/// when its capsules are deleted, like a passport's.
abstract final class Stamps {
  /// [placeName] as the functions keep it as a town (cityOf): dots and
  /// slashes become spaces, spaces collapse, at most 80 characters; null
  /// when nothing is left.
  static String? townKey(String? placeName) {
    if (placeName == null) return null;
    var clean = placeName
        .replaceAll(RegExp(r'[./]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    // Cut after the trim, as the functions do (no second trim).
    if (clean.length > 80) clean = clean.substring(0, 80);
    if (clean.isEmpty || RegExp(r'^__.*__$').hasMatch(clean)) return null;
    return clean;
  }

  /// The stamp a capsule left in [placeName], [countryCode] earns, with the
  /// number of the town (the user's 22nd), or null when the user has
  /// left a capsule in that town before, or the town or country is unknown.
  static ({String town, int number, String country})? newStamp(
    WorldSummary world, {
    required String? countryCode,
    required String? placeName,
  }) {
    final town = townKey(placeName);
    if (town == null || countryCode == null) return null;
    for (final country in world.countries) {
      if (country.code == countryCode && country.cities.containsKey(town)) {
        return null;
      }
    }
    return (town: town, number: world.cityCount + 1, country: countryCode);
  }

  /// The ordinal of [n] in the language of [locale], as "your 22nd town"
  /// needs it: "22nd", "22." (German, Polish), "22-й" (Russian), "22.ª"
  /// (Spanish, a town is feminine).
  static String ordinal(int n, String locale) =>
      switch (locale.split(RegExp('[-_]')).first) {
        'de' || 'pl' => '$n.',
        'ru' => '$n-й',
        'es' => '$n.ª',
        _ => englishOrdinal(n),
      };

  /// "22nd": the English ordinal of [n].
  static String englishOrdinal(int n) {
    final teen = n % 100;
    if (teen >= 11 && teen <= 13) return '${n}th';
    return switch (n % 10) {
      1 => '${n}st',
      2 => '${n}nd',
      3 => '${n}rd',
      _ => '${n}th',
    };
  }
}

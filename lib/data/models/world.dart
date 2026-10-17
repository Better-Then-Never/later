/// One country in a user's world summary (B7): the capsules left there, the
/// towns (capsules each), the first and last visit.
class CountryVisit {
  const CountryVisit({
    required this.code,
    this.capsules = 0,
    this.cities = const {},
    this.first,
    this.last,
  });

  /// ISO 3166 alpha-2 ("PL").
  final String code;
  final int capsules;
  final Map<String, int> cities;
  final DateTime? first;
  final DateTime? last;

  /// Towns, the one with most capsules first (then by name).
  List<String> get towns => cities.keys.toList()
    ..sort((a, b) {
      final byCount = cities[b]!.compareTo(cities[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
}

/// Countries and towns of a user's capsules, kept by the functions in
/// `users/{uid}/world/summary` (one read for the whole view). Capsules made
/// before the app sent their country are not in it.
class WorldSummary {
  const WorldSummary({this.countries = const []});

  /// First visited first.
  final List<CountryVisit> countries;

  static const empty = WorldSummary();

  bool get isEmpty => countries.isEmpty;
  int get countryCount => countries.length;
  int get cityCount => countries.fold(0, (n, c) => n + c.cities.length);
}

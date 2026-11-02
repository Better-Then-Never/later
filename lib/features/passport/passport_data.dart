import '../../data/models/world.dart';

/// The Passport's data, shaped from the world summary the functions keep
/// (`users/{uid}/world/summary`): towns with their country, the pages they
/// fill, what two people share, the year. Pure, so it is tested alone.
///
/// The summary knows per country the capsules, the towns (capsules each)
/// and the first and last visit; it has no date per town and no capsules
/// per year, so nothing here pretends to.
abstract final class PassportData {
  /// Town stamps on one passport page (as the new-stamp moment counts them).
  static const stampsPerPage = 7;

  /// Visas on one page.
  static const visasPerPage = 3;

  /// Every town as a stamp: countries first visited first, in a country the
  /// town with most capsules first.
  static List<PassportTown> towns(WorldSummary world) => [
    for (final country in world.countries)
      for (final town in country.towns)
        PassportTown(
          town: town,
          countryCode: country.code,
          capsules: country.cities[town] ?? 0,
          // The country's first visit is the town's only when the country
          // has just this town.
          first: country.cities.length == 1 ? country.first : null,
          countryFirst: country.first,
        ),
  ];

  /// [items] cut into pages of [perPage] (the last one may be short).
  static List<List<T>> pages<T>(List<T> items, int perPage) => [
    for (var i = 0; i < items.length; i += perPage)
      items.sublist(i, (i + perPage).clamp(0, items.length)),
  ];

  /// The booklet's leaves in order: the cover, You and a friend (when
  /// [together]), the photo page, then the stamps (or the empty page when
  /// there are no towns yet), the visas, and the year last when [year].
  /// Pages are numbered from the photo page (1), like a passport's.
  static List<PassportLeaf> book(
    WorldSummary world, {
    bool together = false,
    bool year = false,
  }) {
    final leaves = <PassportLeaf>[const PassportLeaf(PassportLeafKind.cover)];
    if (together) leaves.add(const PassportLeaf(PassportLeafKind.together));
    var number = 1;
    leaves.add(PassportLeaf(PassportLeafKind.photo, number: number++));
    final towns = world.cityCount;
    if (towns == 0) {
      leaves.add(PassportLeaf(PassportLeafKind.empty, number: number++));
    }
    for (var i = 0; i < towns; i += stampsPerPage) {
      leaves.add(
        PassportLeaf(
          PassportLeafKind.stamps,
          number: number++,
          start: i,
          count: (towns - i).clamp(0, stampsPerPage),
        ),
      );
    }
    final countries = world.countryCount;
    for (var i = 0; i < countries; i += visasPerPage) {
      leaves.add(
        PassportLeaf(
          PassportLeafKind.visas,
          number: number++,
          start: i,
          count: (countries - i).clamp(0, visasPerPage),
        ),
      );
    }
    if (year) leaves.add(PassportLeaf(PassportLeafKind.year, number: number));
    return leaves;
  }

  /// The leaf the Passport opens at: the stamps page with [focusTown]'s
  /// stamp (the last stamps page while the summary has not caught up, or
  /// the empty page); else You and a friend when there; else the cover.
  static int openAt(
    List<PassportLeaf> leaves,
    List<PassportTown> towns, {
    String? focusTown,
  }) {
    if (focusTown != null) {
      final at = towns.indexWhere((t) => t.town == focusTown);
      var last = -1;
      for (var i = 0; i < leaves.length; i++) {
        final leaf = leaves[i];
        if (leaf.kind == PassportLeafKind.empty) return i;
        if (leaf.kind != PassportLeafKind.stamps) continue;
        if (at >= leaf.start && at < leaf.start + leaf.count) return i;
        last = i;
      }
      if (last >= 0) return last;
    }
    final together = leaves.indexWhere(
      (l) => l.kind == PassportLeafKind.together,
    );
    return together >= 0 ? together : 0;
  }

  /// The first stamp's day: the earliest first visit of any country.
  static DateTime? since(WorldSummary world) {
    DateTime? first;
    for (final c in world.countries) {
      final d = c.first;
      if (d != null && (first == null || d.isBefore(first))) first = d;
    }
    return first;
  }

  /// [name] as a passport prints it: the last word the surname, the rest
  /// the given names. One word (or none) is just a name.
  static PassportName splitName(String name) {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.length < 2) {
      return PassportName(given: words.isEmpty ? '' : words.single);
    }
    return PassportName(
      surname: words.last,
      given: words.sublist(0, words.length - 1).join(' '),
    );
  }

  /// A machine-readable line: [parts] in capitals, spaces as `<`, joined
  /// by `<<`, filled with `<` up to [length] (cut when longer).
  static String mrz(List<String> parts, {int length = 30}) {
    final text = parts
        .where((p) => p.trim().isNotEmpty)
        .map((p) => p.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '<'))
        .join('<<');
    return text.length >= length
        ? text.substring(0, length)
        : text.padRight(length, '<');
  }

  /// What [mine] and [theirs] have in common, and what only one has.
  static PassportComparison compare(WorldSummary mine, WorldSummary theirs) {
    final theirCountries = {for (final c in theirs.countries) c.code: c};
    final myCodes = {for (final c in mine.countries) c.code};
    final sharedTowns = <PassportTown>[];
    final sharedCountries = <String>[];
    for (final country in mine.countries) {
      final other = theirCountries[country.code];
      if (other == null) continue;
      sharedCountries.add(country.code);
      for (final town in country.towns) {
        final theirCount = other.cities[town];
        if (theirCount == null) continue;
        // Their stamp (it is their Passport): their capsules and days.
        sharedTowns.add(
          PassportTown(
            town: town,
            countryCode: country.code,
            capsules: theirCount,
            first: other.cities.length == 1 ? other.first : null,
            countryFirst: other.first,
          ),
        );
      }
    }
    return PassportComparison(
      countries: sharedCountries,
      towns: sharedTowns,
      onlyMine: [
        for (final c in mine.countries)
          if (!theirCountries.containsKey(c.code)) c.code,
      ],
      onlyTheirs: [
        for (final c in theirs.countries)
          if (!myCodes.contains(c.code)) c.code,
      ],
    );
  }

  /// [year] in the summary: the countries with a capsule that year (their
  /// last visit falls in it, at its month), and the ones first entered in
  /// it. Null when no country was visited that year.
  static PassportYear? year(WorldSummary world, int year) {
    final visits = <PassportYearVisit>[];
    final entered = <String>[];
    for (final c in world.countries) {
      final last = c.last ?? c.first;
      if (last == null || last.year != year) continue;
      final isNew = c.first != null && c.first!.year == year;
      visits.add(
        PassportYearVisit(code: c.code, month: last.month, isNew: isNew),
      );
      if (isNew) entered.add(c.code);
    }
    if (visits.isEmpty) return null;
    visits.sort((a, b) => a.month.compareTo(b.month));
    return PassportYear(year: year, visits: visits, entered: entered);
  }
}

/// What a leaf of the booklet shows.
enum PassportLeafKind { cover, together, photo, empty, stamps, visas, year }

/// One leaf of the booklet: its kind, its printed number (0: none), and for
/// stamps and visas which towns or countries ([start], [count]) it holds.
class PassportLeaf {
  const PassportLeaf(
    this.kind, {
    this.number = 0,
    this.start = 0,
    this.count = 0,
  });

  final PassportLeafKind kind;
  final int number;
  final int start;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is PassportLeaf &&
      other.kind == kind &&
      other.number == number &&
      other.start == start &&
      other.count == count;

  @override
  int get hashCode => Object.hash(kind, number, start, count);

  @override
  String toString() => '${kind.name}#$number[$start+$count]';
}

/// One town's stamp.
class PassportTown {
  const PassportTown({
    required this.town,
    required this.countryCode,
    required this.capsules,
    this.first,
    this.countryFirst,
  });

  final String town;
  final String countryCode;
  final int capsules;

  /// The first capsule in this town, when the summary can tell.
  final DateTime? first;

  /// The first capsule in its country.
  final DateTime? countryFirst;

  @override
  bool operator ==(Object other) =>
      other is PassportTown &&
      other.town == town &&
      other.countryCode == countryCode &&
      other.capsules == capsules &&
      other.first == first &&
      other.countryFirst == countryFirst;

  @override
  int get hashCode =>
      Object.hash(town, countryCode, capsules, first, countryFirst);

  @override
  String toString() => '$town ($countryCode)';
}

/// A name as a passport prints it; [surname] is empty for a one-word name.
class PassportName {
  const PassportName({this.surname = '', required this.given});

  final String surname;
  final String given;

  bool get hasSurname => surname.isNotEmpty;
}

/// Two passports side by side ("You and Bob").
class PassportComparison {
  const PassportComparison({
    required this.countries,
    required this.towns,
    required this.onlyMine,
    required this.onlyTheirs,
  });

  /// Countries (codes) both have a stamp in, in my order.
  final List<String> countries;

  /// Towns both left a capsule in, as [theirs] stamped them.
  final List<PassportTown> towns;
  final List<String> onlyMine;
  final List<String> onlyTheirs;
}

/// One year of a passport.
class PassportYear {
  const PassportYear({
    required this.year,
    required this.visits,
    required this.entered,
  });

  final int year;

  /// Countries visited that year, by the month of their latest visit.
  final List<PassportYearVisit> visits;

  /// Countries (codes) first entered that year.
  final List<String> entered;

  int get countryCount => visits.length;
}

/// A country on the year's month line.
class PassportYearVisit {
  const PassportYearVisit({
    required this.code,
    required this.month,
    required this.isNew,
  });

  final String code;

  /// 1 to 12: the month of the latest visit that year.
  final int month;

  /// First entered that year.
  final bool isNew;
}

import 'dart:convert';

import '../../data/models/capsule.dart';
import '../../data/models/geo_position.dart';
import '../../data/models/user_settings.dart';
import '../../data/services/preferences_store.dart';

/// What the place alerts remember on this phone, per account: the home
/// country, where the user is and since when, when they were last welcomed
/// to each country, and which capsules were already announced as nearby.
class PlaceAlertsMemory {
  PlaceAlertsMemory({
    this.home,
    this.country,
    this.countrySince,
    Map<String, DateTime>? welcomed,
    List<String>? nearby,
  }) : welcomed = welcomed ?? {},
       nearby = nearby ?? [];

  /// The country the alerts first found the user in (ISO "PL"); a country
  /// they stay in for a month becomes it.
  String? home;

  /// The country of the last check, and when this stay in it began.
  String? country;
  DateTime? countrySince;

  /// When the user was last welcomed to each country.
  final Map<String, DateTime> welcomed;

  /// Capsules already announced as nearby (oldest first).
  final List<String> nearby;

  static const _name = 'place_alerts';

  static Future<PlaceAlertsMemory> read(
    PreferencesStore prefs,
    String uid,
  ) async {
    try {
      final raw = await prefs.string(uid, _name);
      if (raw == null || raw.isEmpty) return PlaceAlertsMemory();
      final j = jsonDecode(raw) as Map<String, dynamic>;
      DateTime? date(Object? v) => v is String ? DateTime.tryParse(v) : null;
      return PlaceAlertsMemory(
        home: j['home'] as String?,
        country: j['country'] as String?,
        countrySince: date(j['since']),
        welcomed: {
          for (final e in ((j['welcomed'] as Map?) ?? const {}).entries)
            if (date(e.value) case final at?) e.key as String: at,
        },
        nearby: [
          for (final id in (j['nearby'] as List?) ?? const [])
            if (id is String) id,
        ],
      );
    } catch (_) {
      return PlaceAlertsMemory();
    }
  }

  Future<void> save(PreferencesStore prefs, String uid) => prefs.setString(
    uid,
    _name,
    jsonEncode({
      'home': ?home,
      'country': ?country,
      'since': ?countrySince?.toIso8601String(),
      'welcomed': {
        for (final e in welcomed.entries) e.key: e.value.toIso8601String(),
      },
      'nearby': nearby,
    }),
  );
}

/// The place alerts' decisions (capsule v3 phase 4, F3 and F4), apart from
/// where the position and the capsules come from
/// (lib/app/background_places_main.dart).
abstract final class PlaceAlerts {
  /// How close a capsule must be to be announced (F4).
  static const double nearbyRadius = 200;

  /// How long the user is in a new country before the welcome (F3).
  static const stayBeforeWelcome = Duration(hours: 2);

  /// A country welcomes the user again only after this.
  static const welcomeAgainAfter = Duration(days: 30);

  /// A month in one country makes it home.
  static const becomesHome = Duration(days: 30);

  /// How many announced capsules are remembered (the oldest go first).
  static const keepAnnounced = 500;

  /// Capsules within [nearbyRadius] of [at] that the user may open now and
  /// has not: a place capsule whose date came and which they have not
  /// opened there ([unlocked]), or one whose date came and which is still
  /// wrapped for them ([wrapped]). Nearest first, each with its distance;
  /// none already announced.
  static List<(Capsule, double)> nearby({
    required Iterable<Capsule> capsules,
    required GeoPosition at,
    required DateTime now,
    required Set<String> unlocked,
    required bool Function(Capsule capsule) wrapped,
    required Iterable<String> announced,
  }) {
    final skip = announced.toSet();
    final found = <(Capsule, double)>[];
    for (final c in capsules) {
      final spot = c.location;
      if (spot == null || skip.contains(c.id) || !c.isOpen(now)) continue;
      final waits = c.opensHere ? !unlocked.contains(c.id) : wrapped(c);
      if (!waits) continue;
      final metres = at.distanceTo(spot);
      if (metres <= nearbyRadius) found.add((c, metres));
    }
    found.sort((a, b) => a.$2.compareTo(b.$2));
    return found;
  }

  /// Whether [now] (local time) falls in [hours] (they may span midnight,
  /// 22:00 to 07:00), as the server checks its pushes (functions/lib/prefs.js).
  static bool quiet(QuietHours hours, DateTime now) {
    if (!hours.enabled || hours.start == hours.end) return false;
    final minute = now.hour * 60 + now.minute;
    return hours.start < hours.end
        ? minute >= hours.start && minute < hours.end
        : minute >= hours.start || minute < hours.end;
  }

  /// Remembers that [capsuleId] was announced.
  static void announced(PlaceAlertsMemory memory, String capsuleId) {
    memory.nearby
      ..remove(capsuleId)
      ..add(capsuleId);
    if (memory.nearby.length > keepAnnounced) {
      memory.nearby.removeRange(0, memory.nearby.length - keepAnnounced);
    }
  }

  /// The user is in [country] (ISO "PL"; null when unknown) at [now]: the
  /// country to welcome them to now, or null. Updates [memory]. The first
  /// country seen is home; a stay starts when the country changes; after
  /// [stayBeforeWelcome] away from home the user is welcomed, once in
  /// [welcomeAgainAfter].
  /// Without [allowed] (quiet hours, notifications off) the stay is still
  /// followed, but nobody is welcomed: that waits for a later check.
  static String? welcome(
    PlaceAlertsMemory memory,
    String? country,
    DateTime now, {
    bool allowed = true,
  }) {
    if (country == null) return null;
    memory.home ??= country;
    if (country != memory.country) {
      memory
        ..country = country
        ..countrySince = now;
      return null;
    }
    final since = memory.countrySince ?? now;
    final stay = now.difference(since);
    if (stay >= becomesHome) memory.home = country;
    if (country == memory.home || stay < stayBeforeWelcome || !allowed) {
      return null;
    }
    final last = memory.welcomed[country];
    if (last != null && now.difference(last) < welcomeAgainAfter) return null;
    memory.welcomed[country] = now;
    return country;
  }
}

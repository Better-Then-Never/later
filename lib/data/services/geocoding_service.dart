import 'dart:async';

import 'package:geocoding/geocoding.dart';

import '../../core/logging/app_logger.dart';
import '../models/geo_position.dart';

/// A town and its country (ISO 3166 alpha-2, "PL"); either may be missing.
class GeoPlace {
  const GeoPlace({this.name, this.countryCode});

  final String? name;
  final String? countryCode;
}

/// Reverse geocoding to a short place name ("Mountain View") and its
/// country, cached per ~100 m cell so lists and rebuilds do not call the
/// platform geocoder repeatedly (it is rate-limited on iOS).
class GeocodingService {
  GeocodingService({
    Future<List<Placemark>> Function(double latitude, double longitude)?
    placemarks,
  }) : _placemarks = placemarks ?? placemarkFromCoordinates;

  final Future<List<Placemark>> Function(double, double) _placemarks;
  final Map<String, Future<GeoPlace?>> _cache = {};

  static String _key(GeoPosition p) =>
      '${p.latitude.toStringAsFixed(3)},${p.longitude.toStringAsFixed(3)}';

  /// Locality, else sub-administrative area, else administrative area, else
  /// null (no result or geocoder failure).
  Future<String?> placeName(GeoPosition position) async =>
      (await place(position))?.name;

  /// The town and country of [position]; null when the geocoder has
  /// nothing (or failed, e.g. offline).
  Future<GeoPlace?> place(GeoPosition position) {
    final key = _key(position);
    final cached = _cache[key];
    if (cached != null) return cached;
    final lookup = _lookup(position);
    _cache[key] = lookup;
    // Failures are usually transient (offline): do not keep them cached.
    unawaited(
      lookup.then((place) {
        if (place == null) _cache.remove(key);
      }),
    );
    return lookup;
  }

  static final _countryCode = RegExp(r'^[A-Z]{2}$');

  Future<GeoPlace?> _lookup(GeoPosition position) async {
    try {
      final marks = await _placemarks(position.latitude, position.longitude);
      if (marks.isEmpty) return null;
      final p = marks.first;
      String? name;
      for (final candidate in [
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
      ]) {
        if (candidate != null && candidate.trim().isNotEmpty) {
          name = candidate.trim();
          break;
        }
      }
      final code = p.isoCountryCode?.trim().toUpperCase();
      final country = code != null && _countryCode.hasMatch(code) ? code : null;
      if (name == null && country == null) return null;
      return GeoPlace(name: name, countryCode: country);
    } catch (e) {
      AppLogger.debug('Reverse geocoding failed: $e');
      return null;
    }
  }
}

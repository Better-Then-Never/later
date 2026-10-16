import 'dart:async';

import 'package:geocoding/geocoding.dart';

import '../../core/logging/app_logger.dart';
import '../models/geo_position.dart';

/// Reverse geocoding to a short place name ("Mountain View"), cached per
/// ~100 m cell so lists and rebuilds do not call the platform geocoder
/// repeatedly (it is rate-limited on iOS).
class GeocodingService {
  GeocodingService();

  final Map<String, Future<String?>> _cache = {};

  static String _key(GeoPosition p) =>
      '${p.latitude.toStringAsFixed(3)},${p.longitude.toStringAsFixed(3)}';

  /// Locality, else sub-administrative area, else administrative area, else
  /// null (no result or geocoder failure).
  Future<String?> placeName(GeoPosition position) {
    final key = _key(position);
    final cached = _cache[key];
    if (cached != null) return cached;
    final lookup = _lookup(position);
    _cache[key] = lookup;
    // Failures are usually transient (offline): do not keep them cached.
    unawaited(
      lookup.then((name) {
        if (name == null) _cache.remove(key);
      }),
    );
    return lookup;
  }

  static Future<String?> _lookup(GeoPosition position) async {
    try {
      final marks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (marks.isEmpty) return null;
      final p = marks.first;
      for (final candidate in [
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
      ]) {
        if (candidate != null && candidate.trim().isNotEmpty) return candidate;
      }
      return null;
    } catch (e) {
      AppLogger.debug('Reverse geocoding failed: $e');
      return null;
    }
  }
}

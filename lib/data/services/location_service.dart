import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../core/logging/app_logger.dart';
import '../models/geo_position.dart';

enum LocationAvailability { available, serviceDisabled, denied, deniedForever }

/// Device location through `geolocator`, with explicit permission/service
/// states, a timeout and a last-known fallback instead of waiting forever.
class LocationService {
  const LocationService();

  Future<LocationAvailability> availability({bool request = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAvailability.serviceDisabled;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationAvailability.available,
      LocationPermission.deniedForever => LocationAvailability.deniedForever,
      _ => LocationAvailability.denied,
    };
  }

  /// Best effort current position: a fresh fix within [timeout], otherwise the
  /// last known position, otherwise null. With [request], asks for the
  /// permission first when it was not given yet.
  Future<GeoPosition?> currentPosition({
    Duration timeout = const Duration(seconds: 8),
    bool request = false,
  }) async {
    if (await availability(request: request) !=
        LocationAvailability.available) {
      return lastKnownPosition();
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      final position = GeoPosition(p.latitude, p.longitude);
      return position.isValid ? position : await lastKnownPosition();
    } catch (e) {
      AppLogger.debug('No fresh location fix: $e');
      return lastKnownPosition();
    }
  }

  Future<GeoPosition?> lastKnownPosition() async {
    try {
      final p = await Geolocator.getLastKnownPosition();
      if (p == null) return null;
      final position = GeoPosition(p.latitude, p.longitude);
      return position.isValid ? position : null;
    } catch (_) {
      return null;
    }
  }

  /// Position updates every ≥ [distanceFilter] metres. Errors (permission
  /// revoked, service turned off) end up on the stream's error channel.
  Stream<GeoPosition> positions({int distanceFilter = 10}) =>
      Geolocator.getPositionStream(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: distanceFilter,
            ),
          )
          .map((p) => GeoPosition(p.latitude, p.longitude))
          .where((p) => p.isValid);

  Future<bool> openSettings() => Geolocator.openLocationSettings();
}

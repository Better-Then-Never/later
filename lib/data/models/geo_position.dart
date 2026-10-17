import 'dart:math' as math;

/// A latitude/longitude pair, independent of Firestore and Google Maps types.
class GeoPosition {
  const GeoPosition(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// A real place: in range, finite, and not 0,0 (what a failed location
  /// fix looks like; the rules reject it too) (F-18).
  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      !(latitude.abs() < 1e-4 && longitude.abs() < 1e-4);

  /// Rounded to two decimals (about a kilometre), for approximate places.
  GeoPosition get approximate => GeoPosition(
    (latitude * 100).roundToDouble() / 100,
    (longitude * 100).roundToDouble() / 100,
  );

  /// Great-circle distance in metres (haversine).
  double distanceTo(GeoPosition other) {
    const earthRadius = 6371000.0;
    final dLat = _rad(other.latitude - latitude);
    final dLng = _rad(other.longitude - longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(latitude)) *
            math.cos(_rad(other.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _rad(double deg) => deg * math.pi / 180;

  @override
  bool operator ==(Object other) =>
      other is GeoPosition &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPosition($latitude, $longitude)';
}

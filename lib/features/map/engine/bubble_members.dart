import 'dart:math' as math;

import '../map_clusters.dart';

/// The area a tapped MapLibre bubble's capsules cover, for the camera to fit,
/// from the bubble's leaves (GeoJSON point features, as the clustered source
/// lists them). Null when fewer than two capsules have a position, or when
/// they all stand within [spot] degrees of each other (fitting them would zoom
/// in without end; the camera moves in until they split instead).
GeoBounds? bubbleArea(
  Iterable<Map<String, dynamic>> leaves, {
  double spot = 1e-4,
}) {
  var south = 90.0, north = -90.0, west = 180.0, east = -180.0;
  var found = 0;
  for (final leaf in leaves) {
    final geometry = leaf['geometry'];
    if (geometry is! Map) continue;
    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) continue;
    final [lng, lat, ...] = coordinates;
    if (lng is! num || lat is! num) continue;
    found++;
    south = math.min(south, lat.toDouble());
    north = math.max(north, lat.toDouble());
    west = math.min(west, lng.toDouble());
    east = math.max(east, lng.toDouble());
  }
  if (found < 2) return null;
  if (north - south < spot && east - west < spot) return null;
  return GeoBounds(south: south, west: west, north: north, east: east);
}

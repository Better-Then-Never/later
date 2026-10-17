import 'dart:math' as math;

import '../../data/models/capsule.dart';
import '../../data/models/geo_position.dart';

/// A latitude/longitude rectangle (the part of the map on screen). [west]
/// may be greater than [east] when it crosses the 180° meridian.
class GeoBounds {
  const GeoBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  double get _width => east >= west ? east - west : east + 360 - west;

  bool contains(GeoPosition p) {
    if (p.latitude < south || p.latitude > north) return false;
    return east >= west
        ? p.longitude >= west && p.longitude <= east
        : p.longitude >= west || p.longitude <= east;
  }

  /// The rectangle grown by [fraction] of its size on every side, so pins
  /// just outside the screen are ready when it pans a little.
  GeoBounds grownBy(double fraction) {
    final dLat = (north - south) * fraction;
    final dLng = math.min(_width * fraction, 180.0);
    double wrap(double lng) => (lng + 540) % 360 - 180;
    return GeoBounds(
      south: math.max(-85, south - dLat),
      north: math.min(85, north + dLat),
      west: wrap(west - dLng),
      east: wrap(east + dLng),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GeoBounds &&
      other.south == south &&
      other.west == west &&
      other.north == north &&
      other.east == east;

  @override
  int get hashCode => Object.hash(south, west, north, east);
}

/// Something the map shows: one capsule's pin, or a numbered bubble for
/// [count] capsules close together.
class MapItem {
  MapItem.pin(Capsule this.capsule)
    : id = 'capsule:${capsule.id}',
      count = 1,
      bounds = null,
      position = null;

  const MapItem.cluster({
    required this.id,
    required this.count,
    required GeoBounds this.bounds,
    required this.position,
  }) : capsule = null;

  final String id;
  final Capsule? capsule;
  final int count;

  /// Where the bubble's capsules are (a tap zooms to them).
  final GeoBounds? bounds;
  final GeoPosition? position;

  bool get isCluster => capsule == null;

  GeoPosition get at => capsule?.location ?? position!;
}

/// Groups the capsules around [view] into what the map shows (F-10, D-19).
///
/// Capsules are bucketed on a grid of [cellPx] map pixels at the floor of
/// [zoom] (the Web Mercator pixels Google Maps draws in, about one dp each):
/// a bucket with one capsule is its pin, a fuller one a numbered bubble at
/// the members' mean position. Only capsules in [view] grown by half its
/// size count, and the grid coarsens until at most [maxItems] remain, so the
/// map never receives more than that many markers. Every marker update runs
/// on Android's main thread, where Flutter's vsync comes from: 1,200 pins at
/// once froze the app for seconds (docs/feel/PERFORMANCE.md).
/// From this zoom level up, every capsule is its own pin.
const pinsOnlyZoom = 19;

List<MapItem> clusterCapsules(
  List<Capsule> capsules, {
  required GeoBounds view,
  required double zoom,
  double cellPx = 64,
  int maxItems = 150,
}) {
  final area = view.grownBy(0.5);
  final inView = [
    for (final c in capsules)
      if (c.location != null && area.contains(c.location!)) c,
  ];
  final z = zoom.floor().clamp(0, 22);
  // Street level: pins only, so capsules in the very same spot can still be
  // reached (a bubble there would only zoom in).
  if (z >= pinsOnlyZoom && inView.length <= maxItems) {
    return [for (final c in inView) MapItem.pin(c)];
  }
  final scale = 256.0 * math.pow(2, z);
  var cell = cellPx;
  for (;;) {
    final buckets = <(int, int), List<Capsule>>{};
    for (final c in inView) {
      final p = c.location!;
      final key = (
        (_x(p.longitude, scale) / cell).floor(),
        (_y(p.latitude, scale) / cell).floor(),
      );
      (buckets[key] ??= []).add(c);
    }
    if (buckets.length <= maxItems || cell > 4096) {
      return [
        for (final e in buckets.entries)
          if (e.value.length == 1)
            MapItem.pin(e.value.single)
          else
            _cluster(
              e.value,
              'cluster:$z:${cell.round()}:${e.key.$1}:${e.key.$2}',
            ),
      ];
    }
    cell *= 1.5;
  }
}

MapItem _cluster(List<Capsule> members, String id) {
  var south = 90.0, north = -90.0, west = 180.0, east = -180.0;
  var lat = 0.0, lng = 0.0;
  for (final c in members) {
    final p = c.location!;
    south = math.min(south, p.latitude);
    north = math.max(north, p.latitude);
    west = math.min(west, p.longitude);
    east = math.max(east, p.longitude);
    lat += p.latitude;
    lng += p.longitude;
  }
  return MapItem.cluster(
    id: id,
    count: members.length,
    bounds: GeoBounds(south: south, west: west, north: north, east: east),
    position: GeoPosition(lat / members.length, lng / members.length),
  );
}

double _x(double longitude, double scale) => (longitude + 180) / 360 * scale;

double _y(double latitude, double scale) {
  final s = math.sin(latitude * math.pi / 180).clamp(-0.9999, 0.9999);
  return (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * scale;
}

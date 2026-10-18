import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Where a place is on screen for a camera, computed in Dart (Web Mercator,
/// 256 dp per tile at zoom 0, as Google Maps draws it) so a Flutter overlay
/// can follow the map frame by frame without asking the platform. The map
/// must not be tilted (the map page turns tilt gestures off).
abstract final class MapProjection {
  static const _tile = 256.0;

  static Offset _world(LatLng p, double zoom) {
    final scale = _tile * math.pow(2, zoom);
    final siny = math
        .sin(p.latitude * math.pi / 180)
        .clamp(-0.9999, 0.9999)
        .toDouble();
    return Offset(
      (p.longitude + 180) / 360 * scale,
      (0.5 - math.log((1 + siny) / (1 - siny)) / (4 * math.pi)) * scale,
    );
  }

  /// [point] on a map of [size] with [padding] (the camera's target sits in
  /// the middle of the padded area), for [camera]. In logical pixels.
  static Offset toScreen(
    LatLng point,
    CameraPosition camera,
    Size size,
    EdgeInsets padding,
  ) {
    final target = _world(camera.target, camera.zoom);
    var d = _world(point, camera.zoom) - target;
    // Across the antimeridian: the shorter way round.
    final world = _tile * math.pow(2, camera.zoom);
    if (d.dx > world / 2) d = d.translate(-world, 0);
    if (d.dx < -world / 2) d = d.translate(world, 0);
    // The map turned by its bearing (clockwise): the screen turns back.
    final b = -camera.bearing * math.pi / 180;
    final rotated = Offset(
      d.dx * math.cos(b) - d.dy * math.sin(b),
      d.dx * math.sin(b) + d.dy * math.cos(b),
    );
    final centre = Offset(
      padding.left + (size.width - padding.horizontal) / 2,
      padding.top + (size.height - padding.vertical) / 2,
    );
    return centre + rotated;
  }
}

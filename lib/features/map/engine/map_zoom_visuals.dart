import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// How the map's layers look at a zoom (docs/map/DECISION.md): pure functions
/// of the zoom, so pinching changes them continuously, and the same stops as
/// MapLibre style expressions ([heatOpacityExpression] ...), which the map
/// evaluates on the GPU every frame. Tests check the two agree.
///
/// Far out the heat shows; closer in the bubbles and pins. Between
/// [markersFrom] and [heatTo] both show, crossfading: the markers are whole
/// before the heat starts to fade, so no zoom shows neither.
abstract final class MapZoomVisuals {
  /// The heat is whole up to here, and gone at [heatTo].
  static const heatFrom = 11.6;
  static const heatTo = 12.3;

  /// Bubbles and pins start here and are whole from [markersTo]: zooming out
  /// they are gone within 0.6 levels (about 0.2 s of a pinch), after the
  /// heat is whole again.
  static const markersFrom = 11.2;
  static const markersTo = 11.8;

  /// Ease in and out (CSS ease-in-out), as `cubic-bezier` in the expressions.
  static const _curve = Cubic(0.42, 0, 0.58, 1);

  static double _between(double zoom, double from, double to) =>
      _curve.transform(((zoom - from) / (to - from)).clamp(0.0, 1.0));

  static double heatOpacity(double zoom) =>
      1 - _between(zoom, heatFrom, heatTo);

  static double markerOpacity(double zoom) =>
      _between(zoom, markersFrom, markersTo);

  /// The heat's radius in dp: one size on the ground (it doubles with each
  /// level, so the picture does not jump as the zoom crosses whole levels),
  /// at least 3 dp far out. Piecewise exponential (base 2) between
  /// [_radiusStops], as MapLibre interpolates them.
  static const _radiusStops = [
    (0.0, 10.0),
    (8.0, 14.0),
    (11.0, 60.0),
    (14.0, 480.0),
  ];

  static double heatRadius(double zoom) {
    const stops = _radiusStops;
    if (zoom <= stops.first.$1) return stops.first.$2;
    for (var i = 1; i < stops.length; i++) {
      final (z1, r1) = stops[i];
      if (zoom <= z1) {
        final (z0, r0) = stops[i - 1];
        final t = (math.pow(2, zoom - z0) - 1) / (math.pow(2, z1 - z0) - 1);
        return r0 + (r1 - r0) * t;
      }
    }
    return stops.last.$2;
  }

  static const _bezier = ['cubic-bezier', 0.42, 0, 0.58, 1];

  static List<Object> heatOpacityExpression() => [
    'interpolate',
    _bezier,
    ['zoom'],
    heatFrom,
    1,
    heatTo,
    0,
  ];

  static List<Object> markerOpacityExpression() => [
    'interpolate',
    _bezier,
    ['zoom'],
    markersFrom,
    0,
    markersTo,
    1,
  ];

  static List<Object> heatRadiusExpression() => [
    'interpolate',
    ['exponential', 2],
    ['zoom'],
    for (final (z, r) in _radiusStops) ...[z, r],
  ];
}

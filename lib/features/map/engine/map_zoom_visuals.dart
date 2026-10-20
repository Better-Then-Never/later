import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// How the map's layers look at a zoom (docs/map/DECISION.md): pure functions
/// of the zoom, so pinching changes them continuously, and the same stops as
/// MapLibre style expressions ([heatOpacityExpression] ...), which the map
/// evaluates on the GPU every frame. Tests check the two agree.
///
/// Far out the heat shows; closer in the bubbles and pins. They hand over in
/// a short band: the heat thins to half while the markers grow in and is
/// gone soon after they are whole, so the base map stays readable under the
/// bubbles; zooming out the bubbles are gone before the heat is whole again.
/// No zoom shows neither, none shows both at full strength (mission 2, §2.2).
abstract final class MapZoomVisuals {
  /// The heat is whole up to here, half at [heatHalf], gone at [heatTo].
  static const heatFrom = 11.0;
  static const heatHalf = 11.5;
  static const heatTo = 11.85;

  /// Bubbles and pins start here and are whole from [markersTo]: zooming out
  /// they are gone within a third of a level (resting a pinch in the band
  /// shows them faint only briefly: no ghosts).
  static const markersFrom = 11.33;
  static const markersTo = 11.68;

  /// Ease in and out (CSS ease-in-out), as `cubic-bezier` in the expressions.
  static const _curve = Cubic(0.42, 0, 0.58, 1);

  static const _heatStops = [(heatFrom, 1.0), (heatHalf, 0.5), (heatTo, 0.0)];
  static const _markerStops = [(markersFrom, 0.0), (markersTo, 1.0)];

  /// How strongly each capsule counts for the heat: lower at city zoom, where
  /// a whole city of capsules would otherwise turn it orange.
  static const _intensityStops = [
    (3.0, 0.5),
    (6.0, 0.22),
    (9.0, 0.24),
    (11.0, 0.2),
  ];

  /// Eased between stops, as `interpolate` with `cubic-bezier` does it.
  static double _eased(double zoom, List<(double, double)> stops) {
    if (zoom <= stops.first.$1) return stops.first.$2;
    for (var i = 1; i < stops.length; i++) {
      final (z1, v1) = stops[i];
      if (zoom <= z1) {
        final (z0, v0) = stops[i - 1];
        return v0 + (v1 - v0) * _curve.transform((zoom - z0) / (z1 - z0));
      }
    }
    return stops.last.$2;
  }

  static double heatOpacity(double zoom) => _eased(zoom, _heatStops);

  static double markerOpacity(double zoom) => _eased(zoom, _markerStops);

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

  static List<Object> _expression(List<(double, Object)> stops) => [
    'interpolate',
    _bezier,
    ['zoom'],
    for (final (z, v) in stops) ...[z, v],
  ];

  static List<Object> heatOpacityExpression() => _expression(_heatStops);

  /// [times]: each marker's own opacity on top (a moving one fading).
  static List<Object> markerOpacityExpression({Object times = 1}) =>
      _expression([(markersFrom, 0), (markersTo, times)]);

  static List<Object> heatIntensityExpression() => [
    'interpolate',
    ['linear'],
    ['zoom'],
    for (final (z, v) in _intensityStops) ...[z, v],
  ];

  static List<Object> heatRadiusExpression() => [
    'interpolate',
    ['exponential', 2],
    ['zoom'],
    for (final (z, r) in _radiusStops) ...[z, r],
  ];
}

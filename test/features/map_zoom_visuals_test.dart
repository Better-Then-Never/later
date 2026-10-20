// How the MapLibre map's layers look at a zoom (docs/map/DECISION.md): the
// heat and the markers hand over in a short band, never both gone, never both
// at full strength (mission 2, §2.2).
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/map/engine/map_zoom_visuals.dart';

void main() {
  test('far out only heat, close in only markers', () {
    expect(MapZoomVisuals.heatOpacity(5), 1);
    expect(MapZoomVisuals.markerOpacity(5), 0);
    expect(MapZoomVisuals.heatOpacity(15), 0);
    expect(MapZoomVisuals.markerOpacity(15), 1);
  });

  test('never a zoom with neither, never both at full strength', () {
    for (var z = 9.0; z <= 14; z += 0.01) {
      final heat = MapZoomVisuals.heatOpacity(z);
      final markers = MapZoomVisuals.markerOpacity(z);
      expect(
        math.max(heat, markers),
        greaterThanOrEqualTo(0.5 - 1e-9),
        reason: 'zoom $z: something shows',
      );
      expect(
        math.min(heat, markers),
        lessThanOrEqualTo(0.5 + 1e-9),
        reason: 'zoom $z: not both strong',
      );
    }
  });

  test('the heat is thin under whole bubbles, and gone soon after', () {
    expect(
      MapZoomVisuals.heatOpacity(MapZoomVisuals.markersTo),
      lessThan(0.25),
    );
    expect(
      MapZoomVisuals.heatTo - MapZoomVisuals.markersTo,
      lessThanOrEqualTo(0.2),
    );
  });

  test('zooming out, the bubbles are gone before the heat is whole', () {
    expect(
      MapZoomVisuals.markersTo - MapZoomVisuals.markersFrom,
      lessThanOrEqualTo(0.35 + 1e-9),
    );
    expect(MapZoomVisuals.markerOpacity(MapZoomVisuals.heatFrom), 0);
  });

  test('smooth: no step anywhere, one way each', () {
    var heat = MapZoomVisuals.heatOpacity(9);
    var markers = MapZoomVisuals.markerOpacity(9);
    for (var z = 9.01; z <= 14; z += 0.01) {
      final h = MapZoomVisuals.heatOpacity(z);
      final m = MapZoomVisuals.markerOpacity(z);
      expect(h, lessThanOrEqualTo(heat + 1e-12));
      expect(m, greaterThanOrEqualTo(markers - 1e-12));
      // A small pinch (0.01 of a level) never changes them by more than 5 %.
      expect((h - heat).abs(), lessThan(0.05));
      expect((m - markers).abs(), lessThan(0.05));
      heat = h;
      markers = m;
    }
  });

  test('the heat keeps one size on the ground from zoom 11 in, and grows '
      'slower farther out', () {
    for (var z = 11.0; z < 13; z += 0.25) {
      expect(
        MapZoomVisuals.heatRadius(z + 1) / MapZoomVisuals.heatRadius(z),
        closeTo(2, 0.1),
        reason: 'zoom $z',
      );
    }
    for (var z = 8.0; z < 10; z += 0.25) {
      expect(
        MapZoomVisuals.heatRadius(z + 1) / MapZoomVisuals.heatRadius(z),
        inInclusiveRange(1.2, 2.0),
        reason: 'zoom $z',
      );
    }
    // Far out a city still shows as a spot of its own.
    expect(MapZoomVisuals.heatRadius(3), greaterThan(8));
  });

  test('the expressions the map evaluates have the same stops', () {
    final heat = MapZoomVisuals.heatOpacityExpression();
    expect(heat.first, 'interpolate');
    final heatStops = heat.sublist(3);
    for (var i = 0; i < heatStops.length; i += 2) {
      final z = (heatStops[i] as num).toDouble();
      expect(
        MapZoomVisuals.heatOpacity(z),
        closeTo((heatStops[i + 1] as num).toDouble(), 1e-9),
      );
    }
    final markers = MapZoomVisuals.markerOpacityExpression();
    expect(markers.sublist(3), [
      MapZoomVisuals.markersFrom,
      0,
      MapZoomVisuals.markersTo,
      1,
    ]);
    final moving = MapZoomVisuals.markerOpacityExpression(
      times: const ['get', 'opacity'],
    );
    expect(moving.last, ['get', 'opacity']);
    final radius = MapZoomVisuals.heatRadiusExpression();
    expect(radius[1], ['exponential', 2]);
    // Each stop in the expression is where the function passes.
    for (var i = 3; i < radius.length; i += 2) {
      final z = (radius[i] as num).toDouble();
      final r = (radius[i + 1] as num).toDouble();
      expect(MapZoomVisuals.heatRadius(z), closeTo(r, 1e-9));
    }
    expect(MapZoomVisuals.heatIntensityExpression().first, 'interpolate');
  });
}

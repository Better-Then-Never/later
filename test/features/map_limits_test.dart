// How far the MapLibre map goes (mission 2, §2.3).
import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/map/engine/map_limits.dart';
import 'package:later/features/map/engine/map_zoom_visuals.dart';

void main() {
  test('never out to the whole world, never past street level', () {
    expect(MapLimits.zoom(0), MapLimits.minZoom);
    expect(MapLimits.zoom(1.5), MapLimits.minZoom);
    expect(MapLimits.zoom(12), 12);
    expect(MapLimits.zoom(22), MapLimits.maxZoom);
    // A 412 dp wide phone at the lowest zoom shows about a tenth of the
    // world's width: a continent, not an ocean.
    const worldDp = 512.0;
    final share = 412 / (worldDp * (1 << MapLimits.minZoom.round()));
    expect(share, lessThan(0.15));
  });

  test('the heat still marks a city at the lowest zoom', () {
    expect(MapZoomVisuals.heatRadius(MapLimits.minZoom), greaterThan(8));
    expect(MapZoomVisuals.heatOpacity(MapLimits.minZoom), 1);
  });
}

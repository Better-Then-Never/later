// Where a place is on screen for a camera (the selected pin overlay, M-02).
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:later/features/map/map_projection.dart';

void main() {
  const size = Size(400, 800);
  const target = LatLng(52.23, 21.01);

  test('the camera target sits in the middle of the padded area', () {
    const camera = CameraPosition(target: target, zoom: 14);
    expect(
      MapProjection.toScreen(target, camera, size, EdgeInsets.zero),
      const Offset(200, 400),
    );
    expect(
      MapProjection.toScreen(
        target,
        camera,
        size,
        const EdgeInsets.only(top: 40, bottom: 160),
      ),
      const Offset(200, 340),
    );
  });

  test('east is right, north is up; each zoom level doubles the distance', () {
    const camera = CameraPosition(target: target, zoom: 14);
    final east = MapProjection.toScreen(
      const LatLng(52.23, 21.02),
      camera,
      size,
      EdgeInsets.zero,
    );
    final north = MapProjection.toScreen(
      const LatLng(52.24, 21.01),
      camera,
      size,
      EdgeInsets.zero,
    );
    expect(east.dx, greaterThan(200));
    expect(east.dy, closeTo(400, 0.001));
    expect(north.dy, lessThan(400));
    // 0.01° of longitude at zoom 14: 256 · 2^14 · 0.01 / 360 ≈ 116.5 dp.
    expect(east.dx - 200, closeTo(256 * math.pow(2, 14) * 0.01 / 360, 0.01));
    final closer = MapProjection.toScreen(
      const LatLng(52.23, 21.02),
      const CameraPosition(target: target, zoom: 13),
      size,
      EdgeInsets.zero,
    );
    expect((east.dx - 200) / (closer.dx - 200), closeTo(2, 1e-9));
  });

  test('a map turned 90° clockwise shows east at the top', () {
    const camera = CameraPosition(target: target, zoom: 14, bearing: 90);
    final east = MapProjection.toScreen(
      const LatLng(52.23, 21.02),
      camera,
      size,
      EdgeInsets.zero,
    );
    expect(east.dx, closeTo(200, 0.001));
    expect(east.dy, lessThan(400));
  });
}

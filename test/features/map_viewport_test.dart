// Each camera the map reports is read with the padding it is relative to
// (M-02): Android keeps the map still when its padding changes, and the
// target it reports moves only with its next camera move.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:later/features/map/map_projection.dart';
import 'package:later/features/map/map_viewport.dart';

const _size = Size(360, 800);
const _low = EdgeInsets.only(top: 30, bottom: 128);
const _high = EdgeInsets.only(top: 30, bottom: 296);
const _start = CameraPosition(target: LatLng(52.2275, 20.9323), zoom: 13);
const _spot = LatLng(52.22, 20.94);

/// Where the camera's target is once the padding changes from [from] to
/// [to] and the map stays still.
CameraPosition _still(CameraPosition camera, EdgeInsets from, EdgeInsets to) {
  // The new padded middle is where the target goes; walk the map to it.
  final shift = (to.top - to.bottom - from.top + from.bottom) / 2;
  final lat = camera.target.latitude;
  // Find the latitude drawn [shift] dp lower/higher than the target.
  var lo = lat - 1, hi = lat + 1;
  for (var i = 0; i < 60; i++) {
    final mid = (lo + hi) / 2;
    final y = MapProjection.toScreen(
      LatLng(mid, camera.target.longitude),
      camera,
      _size,
      EdgeInsets.zero,
    ).dy;
    final want = _size.height / 2 + shift;
    if (y > want) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return CameraPosition(
    target: LatLng((lo + hi) / 2, camera.target.longitude),
    zoom: camera.zoom,
  );
}

Offset _onScreen(MapView view) =>
    MapProjection.toScreen(_spot, view.camera, _size, view.padding);

void main() {
  test('cameras keep the padding while it does not change', () {
    final viewport = MapViewport()..start(_start, _low);
    const moved = CameraPosition(target: LatLng(52.23, 20.93), zoom: 13.5);
    viewport.moved(moved);
    expect(viewport.value, (camera: moved, padding: _low));
  });

  test('a new padding and no camera: the map stood still, so the last '
      'camera keeps its padding', () {
    final viewport = MapViewport()..start(_start, _low);
    final before = _onScreen(viewport.value!);
    viewport
      ..asked(_high)
      ..confirmed();
    expect(viewport.value!.padding, _low);
    expect(_onScreen(viewport.value!), before);
  });

  test('after the map confirms it, the next camera takes the new padding', () {
    final viewport = MapViewport()..start(_start, _low);
    viewport
      ..asked(_high)
      ..confirmed();
    // A camera relative to the new padding, the map still.
    final still = _still(_start, _low, _high);
    final before = _onScreen(viewport.value!);
    viewport.moved(still);
    expect(viewport.value!.padding, _high);
    expect((_onScreen(viewport.value!) - before).distance, lessThan(0.05));
  });

  test('before the map confirms it, the camera tells by not jumping', () {
    final viewport = MapViewport()..start(_start, _low);
    viewport.asked(_high);
    final before = _onScreen(viewport.value!);
    // The map has not taken it yet: a small move, the old padding.
    const nudged = CameraPosition(target: LatLng(52.2274, 20.9323), zoom: 13);
    viewport.moved(nudged);
    expect(viewport.value!.padding, _low);
    // Now it has: the target jumps by half the change, the map does not.
    final still = _still(nudged, _low, _high);
    final nudgedAt = _onScreen(viewport.value!);
    viewport.moved(still);
    expect(viewport.value!.padding, _high);
    expect((_onScreen(viewport.value!) - nudgedAt).distance, lessThan(0.05));
    expect((nudgedAt - before).distance, lessThan(15));
  });

  test('closing right after opening: the last confirmed one wins', () {
    final viewport = MapViewport()..start(_start, _low);
    viewport
      ..asked(_high)
      ..asked(_low)
      ..confirmed()
      ..confirmed();
    viewport.moved(_start);
    expect(viewport.value!.padding, _low);
  });
}

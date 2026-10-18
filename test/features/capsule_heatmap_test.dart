// The far-out map (M-11): heat from every capsule's own place, drawn as
// tiles the map keeps, so panning draws nothing again.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:later/data/models/capsule.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/features/map/capsule_heatmap.dart';

Capsule _at(int i, double lat, double lng) => Capsule(
  id: 'c$i',
  ownerId: 'o',
  title: 't',
  privacy: CapsulePrivacy.public,
  color: CapsuleColor.red,
  location: GeoPosition(lat, lng),
);

img.Image _tile(List<(double, double)> points, {double reference = 1}) =>
    img.decodePng(
      CapsuleHeatmap.renderTile(
        Float64List.fromList([
          for (final (x, y) in points) ...[x, y],
        ]),
        reference,
        14,
        CapsuleHeatmap.ramp,
      ),
    )!;

void main() {
  test('one capsule: a faint, cool spot where it is, nothing far from it', () {
    final tile = _tile([(128, 128)], reference: 40);
    final centre = tile.getPixel(128, 128);
    expect(centre.a, greaterThan(0));
    expect(centre.b, greaterThan(centre.r), reason: 'cool, not warm');
    expect(tile.getPixel(10, 10).a, 0);
    expect(tile.getPixel(128, 128 + 60).a, 0);
  });

  test('a crowd is warmer and stronger, but never a solid patch', () {
    final random = math.Random(3);
    final crowd = [
      for (var i = 0; i < 300; i++)
        (118 + random.nextDouble() * 20, 118 + random.nextDouble() * 20),
    ];
    final busy = _tile(crowd, reference: 40).getPixel(128, 128);
    final lone = _tile([(128, 128)], reference: 40).getPixel(128, 128);
    expect(busy.a, greaterThan(lone.a));
    expect(busy.r, greaterThan(busy.b), reason: 'warm where it is busiest');
    expect(busy.a, lessThanOrEqualTo(255 * CapsuleHeatmap.maxOpacity + 1));
  });

  test('every capsule counts, not the bubbles: two in one spot are hotter', () {
    final one = _tile([(128, 128)], reference: 10).getPixel(128, 128);
    final two = _tile([
      (128, 128),
      (128, 128),
    ], reference: 10).getPixel(128, 128);
    expect(two.a, greaterThan(one.a));
  });

  test('the ramp runs cool to warm and fades out to nothing', () {
    final ramp = CapsuleHeatmap.ramp;
    expect(ramp[3], 0, reason: 'no heat, no colour');
    final last = ramp.length - 4;
    expect(ramp[last], greaterThan(ramp[last + 2]), reason: 'hot is warm');
    expect(ramp[2], greaterThan(ramp[0]), reason: 'faint is cool');
  });

  test('the busiest places set the scale at each zoom', () {
    final city = [
      for (var i = 0; i < 100; i++) (0.5 + i * 1e-6, 0.3 + i * 1e-6),
    ];
    final xs = Float64List.fromList([for (final p in city) p.$1]);
    final ys = Float64List.fromList([for (final p in city) p.$2]);
    final far = CapsuleHeatmap.referenceDensity(xs, ys, 256.0 * 16, 14);
    expect(far, closeTo(100, 1), reason: 'one spot far out');
    expect(
      CapsuleHeatmap.referenceDensity(Float64List(0), Float64List(0), 256, 14),
      1,
    );
  });

  test(
    'tiles depend only on the places: the same ones redraw nothing',
    () async {
      final heatmap = CapsuleHeatmap();
      final capsules = [_at(1, 52.23, 21.01), _at(2, 52.25, 21.03)];
      expect(heatmap.setCapsules(capsules), isTrue);
      expect(heatmap.setCapsules(capsules.reversed), isFalse);
      expect(heatmap.setCapsules([capsules.first]), isTrue);
      // Far from any capsule: no tile at all.
      final empty = await heatmap.getTile(0, 0, 10);
      expect(empty.data, isNull);
    },
  );

  test('a tile over a capsule has its heat', () async {
    final heatmap = CapsuleHeatmap()..setCapsules([_at(1, 52.23, 21.01)]);
    const z = 9;
    final n = math.pow(2, z);
    final x = ((21.01 + 180) / 360 * n).floor();
    final s = math.sin(52.23 * math.pi / 180);
    final y = ((0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * n).floor();
    final tile = await heatmap.getTile(x, y, z);
    expect(tile.data, isNotNull);
    expect(tile, isA<Tile>());
  });

  test('the same heat at every zoom level: the bump has one size on the '
      'ground (no jump when the map swaps levels)', () {
    for (var z = 9; z < 11; z++) {
      expect(
        CapsuleHeatmap.sigmaAt(z + 1),
        closeTo(2 * CapsuleHeatmap.sigmaAt(z), 1e-9),
      );
    }
    // And so the same scale of colours.
    final random = math.Random(4);
    final xs = Float64List.fromList([
      for (var i = 0; i < 300; i++) 0.5 + random.nextDouble() * 1e-3,
    ]);
    final ys = Float64List.fromList([
      for (var i = 0; i < 300; i++) 0.33 + random.nextDouble() * 1e-3,
    ]);
    double at(int z) => CapsuleHeatmap.referenceDensity(
      xs,
      ys,
      256.0 * math.pow(2, z),
      CapsuleHeatmap.sigmaAt(z),
    );
    expect(at(11), closeTo(at(10), 1e-6));
    // Very far out it keeps a smallest size, so a city still shows.
    expect(CapsuleHeatmap.sigmaAt(3), 3);
  });
}

import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart' as img;

import '../../core/theme/app_colors.dart';
import '../../data/models/capsule.dart';

/// The far-out map (M-11): where capsules are, as heat, from every capsule's
/// own place (not the bubbles), below [MapController.markerZoomThreshold].
///
/// Drawn by the map itself as tiles this provides: they stay on the map
/// while it moves, the map keeps the ones it has drawn, and asks for new ones
/// only where it has none, so panning draws nothing again. A tile is drawn in
/// a background isolate. The map forgets its tiles only when the capsules'
/// places change ([setCapsules]).
///
/// Each capsule adds a soft bump ([sigmaAt]); the sum, on a log scale
/// against how dense the busiest places are, picks a colour on a
/// cool-to-warm ramp of the app's own colours and an opacity of at most
/// [maxOpacity]: busy places show warmer, never as a solid patch.
///
/// The bump has one size on the ground, so every zoom level's tiles show the
/// same picture: the map swaps levels as the zoom crosses a whole number
/// (any small pinch), and a bump of fixed pixels made the heat jump bigger
/// and smaller there. Only very far out it keeps a smallest size.
class CapsuleHeatmap implements TileProvider {
  static const id = TileOverlayId('capsules_heatmap');
  static const _tile = 256;

  /// How far one capsule's heat spreads at zoom [z], in dp (one standard
  /// deviation): 14 dp at zoom 11, about 700 m on the ground, at least 3 dp
  /// far out.
  static double sigmaAt(int z) =>
      math.max(3, 14 * math.pow(2, z - 11).toDouble());
  static const maxOpacity = 0.35;

  /// Web Mercator places of the capsules, 0..1 across the world.
  Float64List _xs = Float64List(0);
  Float64List _ys = Float64List(0);
  int _key = 0;
  final Map<int, Future<double>> _reference = {};

  /// Takes the capsules' places; true when they changed (the map must then
  /// forget its tiles).
  bool setCapsules(Iterable<Capsule> capsules) {
    final xs = <double>[], ys = <double>[];
    for (final c in capsules) {
      final p = c.location;
      if (p == null) continue;
      xs.add((p.longitude + 180) / 360);
      final s = math.sin(p.latitude * math.pi / 180).clamp(-0.9999, 0.9999);
      ys.add(0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi));
    }
    final key = Object.hashAllUnordered([
      for (var i = 0; i < xs.length; i++) Object.hash(xs[i], ys[i]),
    ]);
    if (key == _key && xs.length == _xs.length) return false;
    _key = key;
    _xs = Float64List.fromList(xs);
    _ys = Float64List.fromList(ys);
    _reference.clear();
    return true;
  }

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    final z = zoom ?? 0;
    final scale = _tile * math.pow(2, z).toDouble();
    final sigma = sigmaAt(z);
    final margin = 3 * sigma;
    final left = x * _tile - margin, top = y * _tile - margin;
    final right = (x + 1) * _tile + margin, bottom = (y + 1) * _tile + margin;
    final local = <double>[];
    for (var i = 0; i < _xs.length; i++) {
      final wx = _xs[i] * scale, wy = _ys[i] * scale;
      if (wx < left || wx > right || wy < top || wy > bottom) continue;
      local
        ..add(wx - x * _tile)
        ..add(wy - y * _tile);
    }
    if (local.isEmpty) return TileProvider.noTile;
    final reference = await (_reference[z] ??= _referenceIn(
      _xs,
      _ys,
      scale,
      sigma,
    ));
    final png = await _renderIn(
      Float64List.fromList(local),
      reference,
      sigma,
      _ramp,
    );
    return Tile(_tile, _tile, png);
  }

  // Static, so the isolate gets only these values, not the provider.
  static Future<double> _referenceIn(
    Float64List xs,
    Float64List ys,
    double scale,
    double sigma,
  ) => Isolate.run(() => referenceDensity(xs, ys, scale, sigma));

  static Future<Uint8List> _renderIn(
    Float64List points,
    double reference,
    double sigma,
    Uint8List ramp,
  ) => Isolate.run(() => renderTile(points, reference, sigma, ramp));

  /// How dense the busiest places are at a zoom of [scale] world pixels: the
  /// heat under 98 in 100 capsules is at most this (at least one capsule), so
  /// only real hotspots run warm.
  static double referenceDensity(
    Float64List xs,
    Float64List ys,
    double scale,
    double sigma,
  ) {
    final n = xs.length;
    if (n == 0) return 1;
    final reach = 3 * sigma;
    final cells = <(int, int), List<int>>{};
    for (var i = 0; i < n; i++) {
      (cells[((xs[i] * scale) ~/ reach, (ys[i] * scale) ~/ reach)] ??= []).add(
        i,
      );
    }
    final heat = Float64List(n);
    final k = 1 / (2 * sigma * sigma);
    for (var i = 0; i < n; i++) {
      final x = xs[i] * scale, y = ys[i] * scale;
      final cx = x ~/ reach, cy = y ~/ reach;
      var sum = 0.0;
      for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
          for (final j in cells[(cx + dx, cy + dy)] ?? const <int>[]) {
            final ex = xs[j] * scale - x, ey = ys[j] * scale - y;
            final d2 = ex * ex + ey * ey;
            if (d2 <= reach * reach) sum += math.exp(-d2 * k);
          }
        }
      }
      heat[i] = sum;
    }
    heat.sort();
    return math.max(1, heat[(n * 0.98).floor().clamp(0, n - 1)]);
  }

  /// One 256 px tile: [points] are capsules' places in its pixels (x, y
  /// pairs, some just outside it), [reference] how dense busy places are at
  /// its zoom, [ramp] 256 RGBA colours from no heat to the most.
  static Uint8List renderTile(
    Float64List points,
    double reference,
    double sigma,
    Uint8List ramp,
  ) {
    const n = _tile;
    final heat = Float32List(n * n);
    final reach = 3 * sigma;
    final r = reach.ceil();
    // The bump by squared distance, looked up instead of computed.
    final bump = Float32List(r * r + 1);
    for (var d2 = 0; d2 <= r * r; d2++) {
      bump[d2] = math.exp(-d2 / (2 * sigma * sigma));
    }
    for (var i = 0; i < points.length; i += 2) {
      final px = points[i], py = points[i + 1];
      final x0 = math.max(0, (px - r).floor());
      final x1 = math.min(n - 1, (px + r).ceil());
      final y0 = math.max(0, (py - r).floor());
      final y1 = math.min(n - 1, (py + r).ceil());
      for (var y = y0; y <= y1; y++) {
        final dy = y + 0.5 - py;
        final dy2 = dy * dy;
        final row = y * n;
        for (var x = x0; x <= x1; x++) {
          final dx = x + 0.5 - px;
          final d2 = (dx * dx + dy2).round();
          if (d2 < bump.length) heat[row + x] += bump[d2];
        }
      }
    }
    final rgba = Uint8List(n * n * 4);
    final log = math.log(1 + reference);
    for (var i = 0; i < heat.length; i++) {
      final h = heat[i];
      if (h < 0.004) continue;
      final t = math.min(1.0, math.log(1 + h) / log);
      final c = (t * 255).round() * 4;
      rgba
        ..[i * 4] = ramp[c]
        ..[i * 4 + 1] = ramp[c + 1]
        ..[i * 4 + 2] = ramp[c + 2]
        ..[i * 4 + 3] = ramp[c + 3];
    }
    final image = img.Image.fromBytes(
      width: n,
      height: n,
      bytes: rgba.buffer,
      numChannels: 4,
    );
    return img.encodePng(image, level: 1);
  }

  /// Cool to warm, the app's own colours (no red: it means danger in the
  /// app): sparse blue, then green, yellow, and orange where it is busiest.
  /// The opacity rises from nothing at the edge of the heat.
  static final Uint8List _ramp = () {
    const stops = [
      (0.0, AppColors.infoBlue),
      (0.35, AppColors.brandGreen),
      (0.7, AppColors.placeYellow),
      (1.0, AppColors.warningOrange),
    ];
    final ramp = Uint8List(256 * 4);
    for (var i = 0; i < 256; i++) {
      final t = i / 255;
      // The colour climbs slower than the heat: ordinary density stays
      // green, only the hotspots turn yellow and orange.
      final h = t * t;
      var c = stops.last.$2;
      for (var s = 1; s < stops.length; s++) {
        if (h <= stops[s].$1) {
          final (t0, c0) = stops[s - 1];
          final (t1, c1) = stops[s];
          c = Color.lerp(c0, c1, (h - t0) / (t1 - t0))!;
          break;
        }
      }
      final alpha = maxOpacity * math.min(1, t / 0.2) * (0.5 + 0.5 * t);
      ramp
        ..[i * 4] = (c.r * 255).round()
        ..[i * 4 + 1] = (c.g * 255).round()
        ..[i * 4 + 2] = (c.b * 255).round()
        ..[i * 4 + 3] = (alpha * 255).round();
    }
    return ramp;
  }();

  /// The ramp, for tests.
  static Uint8List get ramp => _ramp;
}

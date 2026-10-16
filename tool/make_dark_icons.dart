// Generates the dark-theme variants of the hand-drawn icons:
//   assets/icons/<group>/<name>.png  ->  assets/icons_dark/<group>/<name>.png
//
// Only achromatic pixels change: a black stroke becomes light, a white fill
// becomes dark; brand-green strokes and coloured dots stay as drawn. Partly
// transparent anti-aliasing keeps its alpha. Run after adding or changing an
// icon:
//
//   dart run tool/make_dark_icons.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Lightness of a black stroke and of a white fill in dark mode.
const _strokeLight = 0.93;
const _fillDark = 0.15;

/// Saturation below which a pixel counts as black, white or grey.
const _achromatic = 0.16;

void main() {
  final source = Directory('assets/icons');
  var written = 0;
  for (final entity in source.listSync(recursive: true)) {
    if (entity is! File || !entity.path.toLowerCase().endsWith('.png')) {
      continue;
    }
    final relative = entity.path
        .replaceAll('\\', '/')
        .substring('assets/icons/'.length);
    final decoded = img.decodePng(entity.readAsBytesSync());
    if (decoded == null) {
      stderr.writeln('skipped (not decodable): ${entity.path}');
      continue;
    }
    final image = decoded.convert(numChannels: 4);
    // White icons are drawn over photos and the camera preview: they look
    // the same in both themes, so they get no dark variant.
    if (_mostlyLight(image)) {
      final stale = File('assets/icons_dark/$relative');
      if (stale.existsSync()) stale.deleteSync();
      continue;
    }
    for (final p in image) {
      final r = p.r / 255, g = p.g / 255, b = p.b / 255;
      final maxC = math.max(r, math.max(g, b));
      final minC = math.min(r, math.min(g, b));
      final saturation = maxC == 0 ? 0.0 : (maxC - minC) / maxC;
      if (saturation > _achromatic) continue;
      // Lightness 0 (black) -> stroke, 1 (white) -> fill.
      final lightness = (maxC + minC) / 2;
      final v = _strokeLight + (_fillDark - _strokeLight) * lightness;
      final c = (v * 255).round().clamp(0, 255);
      p
        ..r = c
        ..g = c
        ..b = c;
    }
    final out = File('assets/icons_dark/$relative');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(img.encodePng(image));
    written++;
  }
  stdout.writeln('wrote $written dark icons to assets/icons_dark/');
}

/// A white icon: light on average and (almost) no dark stroke. Black-outlined
/// icons with big white fills have a dark stroke, so they still get a variant.
bool _mostlyLight(img.Image image) {
  var sum = 0.0;
  var count = 0;
  var dark = 0;
  for (final p in image) {
    if (p.a < 128) continue;
    final r = p.r / 255, g = p.g / 255, b = p.b / 255;
    final lightness =
        (math.max(r, math.max(g, b)) + math.min(r, math.min(g, b))) / 2;
    sum += lightness;
    if (lightness < 0.3) dark++;
    count++;
  }
  return count > 0 && sum / count > 0.75 && dark / count < 0.03;
}

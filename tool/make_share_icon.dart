// Redraws the profile's share icon (F-43): the old one was a paper plane,
// the same picture as "send". The ring of the existing icon is kept (all
// profile icons share it); inside it goes the usual share sign, three linked
// nodes, in the ring's stroke weight. Also writes the same drawing as an SVG
// (docs/feel/icons/share.svg) for the owner to review or hand to a designer.
//
//   dart run tool/make_share_icon.dart     (then tool/make_dark_icons.dart)
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _file = 'assets/icons/profile/share.png';
const _scale = 4;

void main() {
  final icon = img.decodePng(File(_file).readAsBytesSync())!;
  final w = icon.width, h = icon.height;

  // The ring: outer edges on the middle row and column.
  final (left, right) = _edges([
    for (var x = 0; x < w; x++) icon.getPixel(x, h ~/ 2).a > 128,
  ]);
  final (top, bottom) = _edges([
    for (var y = 0; y < h; y++) icon.getPixel(w ~/ 2, y).a > 128,
  ]);
  final cx = (left + right) / 2, cy = (top + bottom) / 2;
  final outer = (right - left) / 2;
  final stroke = _firstRun([
    for (var x = left; x < w; x++) icon.getPixel(x, h ~/ 2).a > 128,
  ]).toDouble();
  final inner = outer - stroke;

  // Clear everything inside the ring.
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final d = math.sqrt(math.pow(x - cx, 2) + math.pow(y - cy, 2));
      if (d < inner - 1) icon.setPixelRgba(x, y, 255, 255, 255, 0);
    }
  }

  // The share sign, relative to the inner radius.
  final r = inner;
  final nodeR = 0.2 * r;
  final nodes = [
    (cx - 0.44 * r, cy),
    (cx + 0.38 * r, cy - 0.46 * r),
    (cx + 0.38 * r, cy + 0.46 * r),
  ];
  final glyph = img.Image(width: w * _scale, height: h * _scale, numChannels: 4)
    ..clear(img.ColorRgba8(255, 255, 255, 0));
  final ink = img.ColorRgba8(255, 255, 255, 255);
  void line(double x1, double y1, double x2, double y2) => img.drawLine(
    glyph,
    x1: (x1 * _scale).round(),
    y1: (y1 * _scale).round(),
    x2: (x2 * _scale).round(),
    y2: (y2 * _scale).round(),
    color: ink,
    thickness: stroke * _scale,
  );
  for (final (x, y) in nodes) {
    const steps = 48;
    for (var i = 0; i < steps; i++) {
      final a = 2 * math.pi * i / steps, b = 2 * math.pi * (i + 1) / steps;
      line(
        x + nodeR * math.cos(a),
        y + nodeR * math.sin(a),
        x + nodeR * math.cos(b),
        y + nodeR * math.sin(b),
      );
    }
  }
  // Links from the left node to the other two, edge to edge.
  final links = <(double, double, double, double)>[];
  for (final (x, y) in nodes.skip(1)) {
    final (lx, ly) = nodes.first;
    final d = math.sqrt(math.pow(x - lx, 2) + math.pow(y - ly, 2));
    final ux = (x - lx) / d, uy = (y - ly) / d;
    final gap = nodeR + stroke * 0.5;
    links.add((lx + ux * gap, ly + uy * gap, x - ux * gap, y - uy * gap));
    line(lx + ux * gap, ly + uy * gap, x - ux * gap, y - uy * gap);
  }
  final small = img.copyResize(
    glyph,
    width: w,
    height: h,
    interpolation: img.Interpolation.average,
  );
  img.compositeImage(icon, small);
  File(_file).writeAsBytesSync(img.encodePng(icon));

  // The same drawing as an SVG.
  String n(double v) => v.toStringAsFixed(1);
  final svg = StringBuffer()
    ..writeln(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $w $h" '
      'fill="none" stroke="#ffffff" stroke-width="${n(stroke)}" stroke-linecap="round">',
    )
    ..writeln(
      '  <circle cx="${n(cx)}" cy="${n(cy)}" r="${n(outer - stroke / 2)}"/>',
    );
  for (final (x, y) in nodes) {
    svg.writeln('  <circle cx="${n(x)}" cy="${n(y)}" r="${n(nodeR)}"/>');
  }
  for (final (x1, y1, x2, y2) in links) {
    svg.writeln(
      '  <line x1="${n(x1)}" y1="${n(y1)}" x2="${n(x2)}" y2="${n(y2)}"/>',
    );
  }
  svg.writeln('</svg>');
  Directory('docs/feel/icons').createSync(recursive: true);
  File('docs/feel/icons/share.svg').writeAsStringSync(svg.toString());
  stdout.writeln('wrote $_file and docs/feel/icons/share.svg');
}

(int, int) _edges(List<bool> opaque) =>
    (opaque.indexOf(true), opaque.lastIndexOf(true));

int _firstRun(List<bool> opaque) {
  final start = opaque.indexOf(true);
  final end = opaque.indexOf(false, start);
  return end - start;
}

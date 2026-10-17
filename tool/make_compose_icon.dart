// Redraws the "new message" icon (a square with a pencil) at 144 px: the
// hand-made one was 36 px, blurry at the ~45 dp it is shown (F-30). Same
// shape and weight, drawn at 4x and averaged down for smooth edges. Then
// run tool/make_dark_icons.dart for the dark variant.
//
//   dart run tool/make_compose_icon.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _size = 144;
const _scale = 4;

void main() {
  const s = _size * _scale;
  final canvas = img.Image(width: s, height: s, numChannels: 4)
    ..clear(img.ColorRgba8(0, 0, 0, 0));
  final ink = img.ColorRgba8(0, 0, 0, 255);
  double u(double v) => v * _scale;

  // The square: a rounded outline, open at the top right for the pencil.
  const stroke = 12.0;
  const left = 18.0, top = 30.0, right = 112.0, bottom = 124.0, r = 18.0;
  void line(double x1, double y1, double x2, double y2) => img.drawLine(
    canvas,
    x1: u(x1).round(),
    y1: u(y1).round(),
    x2: u(x2).round(),
    y2: u(y2).round(),
    color: ink,
    thickness: u(stroke),
  );
  void arc(double cx, double cy, double from, double to) {
    const steps = 24;
    for (var i = 0; i < steps; i++) {
      final a = from + (to - from) * i / steps;
      final b = from + (to - from) * (i + 1) / steps;
      line(
        cx + r * math.cos(a),
        cy + r * math.sin(a),
        cx + r * math.cos(b),
        cy + r * math.sin(b),
      );
    }
  }

  line(left + r, top, 72, top); // top edge, up to the gap
  arc(left + r, top + r, math.pi, 1.5 * math.pi); // top left
  line(left, top + r, left, bottom - r); // left edge
  arc(left + r, bottom - r, 0.5 * math.pi, math.pi); // bottom left
  line(left + r, bottom, right - r, bottom); // bottom edge
  arc(right - r, bottom - r, 0, 0.5 * math.pi); // bottom right
  line(right, bottom - r, right, 78); // right edge, up to the gap

  // The pencil: a 45° bar from the square's middle to the top right, with a
  // pointed tip at the lower left.
  const tipX = 60.0, tipY = 84.0, endX = 128.0, endY = 16.0;
  const half = 11.0; // half the pencil's width
  final dx = endX - tipX, dy = endY - tipY;
  final length = math.sqrt(dx * dx + dy * dy);
  final nx = -dy / length * half, ny = dx / length * half;
  const tipLength = 18.0;
  final bx = tipX + dx / length * tipLength, by = tipY + dy / length * tipLength;
  // Outline of the pencil body and its tip.
  line(bx + nx, by + ny, endX + nx, endY + ny);
  line(bx - nx, by - ny, endX - nx, endY - ny);
  line(endX + nx, endY + ny, endX - nx, endY - ny);
  line(bx + nx, by + ny, tipX, tipY);
  line(bx - nx, by - ny, tipX, tipY);
  line(bx + nx, by + ny, bx - nx, by - ny);

  final out = img.copyResize(
    canvas,
    width: _size,
    height: _size,
    interpolation: img.Interpolation.average,
  );
  File('assets/icons/messages/new_message.png').writeAsBytesSync(
    img.encodePng(out),
  );
  stdout.writeln('wrote assets/icons/messages/new_message.png ($_size px)');
}

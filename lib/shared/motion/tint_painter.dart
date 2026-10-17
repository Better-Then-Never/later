import 'package:flutter/widgets.dart';

/// Paints [color] over a widget, its alpha scaled by [amount] (0 to 1): the
/// cheap fade. Over a plain background, covering a widget with that
/// background and thinning the cover looks exactly like fading the widget
/// in; dimming a page is the same with a scrim. Unlike opacity, it needs no
/// offscreen layer, which on Impeller costs a pass per frame (MOTION_CATALOG.md).
///
/// Use as a `CustomPaint.foregroundPainter`; it repaints with [amount].
class TintPainter extends CustomPainter {
  TintPainter(this.amount, this.color) : super(repaint: amount);

  final Animation<double> amount;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = amount.value;
    if (t <= 0) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: color.a * t.clamp(0, 1)),
    );
  }

  @override
  bool shouldRepaint(TintPainter old) =>
      old.amount != amount || old.color != color;
}

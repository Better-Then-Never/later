import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

/// The outline of a town's stamp.
enum InkStampShape { oval, round, rect }

/// A town's stamp (Figma "Passport / Stamp"): a thick border and a thin one
/// inside it, [top] (the town), [middle] (a day or a count) with the pin,
/// and [bottom] (the country), all in [ink]. Drawn at its own size
/// ([sizeOf]); scale it with a [FittedBox] to fit a slot.
class InkStamp extends StatelessWidget {
  const InkStamp({
    super.key,
    required this.ink,
    required this.top,
    required this.middle,
    required this.bottom,
    this.shape = InkStampShape.oval,
  });

  final Color ink;
  final String top;
  final String middle;
  final String bottom;
  final InkStampShape shape;

  static Size sizeOf(InkStampShape shape) => switch (shape) {
    InkStampShape.oval => const Size(172.8, 113.4),
    InkStampShape.round => const Size(124, 124),
    InkStampShape.rect => const Size(172.8, 100),
  };

  @override
  Widget build(BuildContext context) =>
      // Drawn art at a fixed size: the words keep their size with the
      // borders (the pages label their stamps for screen readers).
      MediaQuery.withNoTextScaling(child: _stamp());

  Widget _stamp() {
    TextStyle style(double size, {double spacing = 0, double height = 1.1}) =>
        TextStyle(
          fontFamily: kAppFontFamily,
          fontSize: size,
          height: height,
          letterSpacing: spacing,
          fontWeight: FontWeight.bold,
          color: ink,
        );
    final size = sizeOf(shape);
    final painter = _InkStampPainter(ink, shape);
    if (shape == InkStampShape.oval) {
      // The new-stamp moment's stamp, as the design drew it.
      Widget line(String text, TextStyle style, double top, {double dx = 0}) =>
          Positioned(
            left: 13.5 + dx,
            top: top,
            width: 145.8,
            child: Text(
              text,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              softWrap: false,
              style: style,
            ),
          );
      return SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: painter)),
            line(top, style(13.5, spacing: 1.62), 16.2),
            line(middle, style(17.55, height: 1.25), 48.6, dx: 10.8),
            line(bottom, style(13.5, spacing: 1.62), 83.7),
          ],
        ),
      );
    }
    // Round and rect: lines that shrink to fit instead of fading.
    Widget line(String text, TextStyle style, double top, double inset) =>
        Positioned(
          left: inset,
          right: inset,
          top: top,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(text, maxLines: 1, softWrap: false, style: style),
            ),
          ),
        );
    final round = shape == InkStampShape.round;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: painter)),
          if (round) ...[
            line(top, style(11.5, spacing: 1.2), 22, 18),
            line(middle, style(15, height: 1.2), 62, 12),
            line(bottom, style(11.5, spacing: 1.2), 88, 22),
          ] else ...[
            line(top, style(12.5, spacing: 1.5), 15, 16),
            Positioned(
              left: 40,
              right: 16,
              top: 39,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    middle,
                    maxLines: 1,
                    softWrap: false,
                    style: style(17, height: 1.25),
                  ),
                ),
              ),
            ),
            line(bottom, style(12.5, spacing: 1.5), 71, 16),
          ],
        ],
      ),
    );
  }
}

/// The stamp's borders and pin, drawn from the design's vectors.
class _InkStampPainter extends CustomPainter {
  const _InkStampPainter(this.ink, this.shape);

  final Color ink;
  final InkStampShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    // The design strokes each border 7.02 and 2.7 wide and masks it to the
    // shape: half of each shows, inside the line.
    final outer = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.51;
    final inner = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35;
    final Offset pinAt;
    switch (shape) {
      case InkStampShape.oval:
        canvas
          ..drawOval(
            const Rect.fromLTWH(0, 0, 172.8, 113.4).deflate(1.755),
            outer,
          )
          ..drawOval(
            const Rect.fromLTWH(6.75, 6.75, 159.3, 99.9).deflate(0.675),
            inner,
          );
        pinAt = const Offset(18.9, 47.25);
      case InkStampShape.round:
        final box = Offset.zero & size;
        canvas
          ..drawOval(box.deflate(1.755), outer)
          ..drawOval(box.deflate(6.75 + 0.675), inner);
        pinAt = Offset(size.width / 2 - 7.29, 40);
      case InkStampShape.rect:
        final box = Offset.zero & size;
        canvas
          ..drawRRect(
            RRect.fromRectAndRadius(
              box.deflate(1.755),
              const Radius.circular(8),
            ),
            outer,
          )
          ..drawRRect(
            RRect.fromRectAndRadius(
              box.deflate(6.75 + 0.675),
              const Radius.circular(4),
            ),
            inner,
          );
        pinAt = const Offset(20, 40);
    }
    // The pin (14.58 × 19.44), hole and all.
    canvas
      ..save()
      ..translate(pinAt.dx, pinAt.dy);
    final pin = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(7.29, 0)
      ..cubicTo(3.2805, 0, 0, 3.2805, 0, 7.29)
      ..cubicTo(0, 12.7575, 7.29, 19.44, 7.29, 19.44)
      ..cubicTo(7.29, 19.44, 14.58, 12.7575, 14.58, 7.29)
      ..cubicTo(14.58, 3.2805, 11.2995, 0, 7.29, 0)
      ..close()
      ..addOval(
        Rect.fromCircle(center: const Offset(7.29, 7.29), radius: 2.916),
      );
    canvas
      ..drawPath(pin, Paint()..color = ink)
      ..restore();
  }

  @override
  bool shouldRepaint(_InkStampPainter old) =>
      old.ink != ink || old.shape != shape;
}

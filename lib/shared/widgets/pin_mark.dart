import 'package:flutter/material.dart';

/// A small pushpin drawn in [color]: a round head on a short needle. Marks
/// pinned chats and pinned friends (no pin exists in the icon set).
class PinMark extends StatelessWidget {
  const PinMark({super.key, required this.color, this.size = 12});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(size * 0.875, size),
    painter: _PinPainter(color: color),
  );
}

class _PinPainter extends CustomPainter {
  const _PinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final head = Offset(size.width / 2, size.height * 0.33);
    canvas
      ..drawCircle(head, size.width * 0.34, paint)
      ..drawLine(head, Offset(size.width / 2, size.height - 1), paint);
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}

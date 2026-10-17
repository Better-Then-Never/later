import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';

/// Marks a loop capsule on a still picture (lists, the map card): a small
/// dark disc with a circling arrow, drawn in the icons' rounded stroke.
class LoopMark extends StatelessWidget {
  const LoopMark({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.capsulesLoopMark,
    child: Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.2),
      decoration: const BoxDecoration(
        color: AppColors.mediaScrim,
        shape: BoxShape.circle,
      ),
      child: const CustomPaint(painter: _LoopPainter()),
    ),
  );
}

class _LoopPainter extends CustomPainter {
  const _LoopPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onMedia
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.16
      ..strokeCap = StrokeCap.round;
    final r = size.width / 2 - paint.strokeWidth / 2;
    final c = size.center(Offset.zero);
    // Most of a circle, then an arrow head where it ends.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      math.pi * 1.6,
      false,
      paint,
    );
    final end =
        c + Offset(math.cos(math.pi * 1.1), math.sin(math.pi * 1.1)) * r;
    canvas
      ..drawLine(end, end + Offset(r * 0.55, -r * 0.05), paint)
      ..drawLine(end, end + Offset(r * 0.1, -r * 0.55), paint);
  }

  @override
  bool shouldRepaint(_LoopPainter old) => false;
}

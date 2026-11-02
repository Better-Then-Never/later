import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The passport's security print (Figma "Passport / Guilloche"): eighteen
/// ovals, 280 × 96, turned 10° apart round the middle of a 300 square, in
/// passport ink.
class GuillochePainter extends CustomPainter {
  const GuillochePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.passportInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas
      ..save()
      ..scale(size.width / 300, size.height / 300)
      ..translate(150, 150);
    for (var i = 0; i < 18; i++) {
      canvas
        ..save()
        ..rotate(i * 10 * math.pi / 180);
      canvas
        ..drawOval(
          Rect.fromCenter(center: Offset.zero, width: 280, height: 96),
          paint,
        )
        ..restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(GuillochePainter old) => false;
}

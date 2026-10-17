import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_text_styles.dart';

/// "typing" under the friend's name in the chat header, with three dots
/// that rise in turn while it shows (still dots with reduced motion).
class TypingLabel extends StatefulWidget {
  const TypingLabel({super.key, required this.text});

  final String text;

  @override
  State<TypingLabel> createState() => _TypingLabelState();
}

class _TypingLabelState extends State<TypingLabel>
    with SingleTickerProviderStateMixin {
  // One wave of the three dots; continuous feedback, so longer than the
  // motion tokens (MOTION_CATALOG.md rule 5).
  late final AnimationController _wave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(vsync: this, duration: AppMotion.slow * 4);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _wave.stop();
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.body.copyWith(color: AppColors.brandGreen);
    return Semantics(
      liveRegion: true,
      label: widget.text,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(widget.text, style: style),
            const SizedBox(width: 2),
            CustomPaint(
              size: const Size(16, 10),
              painter: _DotsPainter(wave: _wave, color: AppColors.brandGreen),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({required this.wave, required this.color})
    : super(repaint: wave);

  final Animation<double> wave;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const radius = 1.6;
    for (var i = 0; i < 3; i++) {
      // Each dot lifts up to 3 dp, a third of a wave after the one before.
      final phase = (wave.value - i / 3) % 1;
      final lift = phase < 0.5 ? math.sin(phase * 2 * math.pi) * 3 : 0.0;
      canvas.drawCircle(
        Offset(radius + i * 5.5, size.height - radius - 1 - lift),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.color != color;
}

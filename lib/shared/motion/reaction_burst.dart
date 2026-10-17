import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';

/// A small celebration when a reaction becomes the user's: [child] (the
/// emoji) grows to 135 % and settles while six dots fly out of it and fade
/// (MOTION_CATALOG.md, "Reactions"). It plays when [active] turns true, not
/// for a reaction that was already there when it was built. The dots are
/// painted (no layers); reduced motion: nothing plays.
class ReactionBurst extends StatefulWidget {
  const ReactionBurst({
    super.key,
    required this.active,
    required this.child,
    this.color = AppColors.brandGreen,
  });

  final bool active;
  final Widget child;
  final Color color;

  @override
  State<ReactionBurst> createState() => _ReactionBurstState();
}

class _ReactionBurstState extends State<ReactionBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _burst = AnimationController(vsync: this, duration: AppMotion.reveal);
    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.35,
        ).chain(CurveTween(curve: AppMotion.enter)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.35,
          end: 1.0,
        ).chain(CurveTween(curve: AppMotion.standardCurve)),
        weight: 60,
      ),
    ]).animate(_burst);
  }

  @override
  void didUpdateWidget(ReactionBurst old) {
    super.didUpdateWidget(old);
    if (!old.active && widget.active && !AppMotion.reduced(context)) {
      _burst.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _Dots(_burst, widget.color),
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}

class _Dots extends CustomPainter {
  _Dots(this.progress, this.color) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final center = size.center(Offset.zero);
    final reach = AppMotion.enter.transform(t);
    final from = size.shortestSide * 0.45;
    final to = size.shortestSide * 0.95;
    final paint = Paint()..color = color.withValues(alpha: color.a * (1 - t));
    for (var i = 0; i < 6; i++) {
      final angle = (i * 60 + 30) * math.pi / 180;
      final distance = from + (to - from) * reach;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
        0.8 + 2.2 * (1 - t),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Dots old) =>
      old.progress != progress || old.color != color;
}

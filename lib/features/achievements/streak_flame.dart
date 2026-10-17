import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// The streak's flame (an emoji, the app's only fire). It swells twice when
/// it appears, then rests; give it a new key to play again (the streak grew).
/// [greyed]: the streak is at risk (today not counted yet), the flame has no
/// colour. Reduced motion: still.
class StreakFlame extends StatefulWidget {
  const StreakFlame({super.key, this.size = 14, this.greyed = false});

  final double size;
  final bool greyed;

  /// A grey flame: the luminance of each colour, alpha kept.
  static const _grey = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 0.55, 0, //
  ]);

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with SingleTickerProviderStateMixin {
  // Created up front: a first use in dispose() would look up TickerMode on
  // a deactivated element (with reduced motion it never runs).
  late final AnimationController _flicker;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Two swells of two slow beats each.
    _flicker = AnimationController(vsync: this, duration: AppMotion.slow * 4);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !AppMotion.reduced(context)) {
      _started = true;
      _flicker.forward();
    }
  }

  @override
  void dispose() {
    _flicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget flame = Text('🔥', style: TextStyle(fontSize: widget.size));
    if (widget.greyed) {
      flame = ColorFiltered(colorFilter: StreakFlame._grey, child: flame);
    }
    return AnimatedBuilder(
      animation: _flicker,
      child: flame,
      builder: (context, child) {
        // Two quick swells, back to rest at the end.
        final t = _flicker.value;
        final swell = math.pow(math.sin(t * 2 * math.pi), 2).toDouble();
        return Transform.scale(
          scale: 1 + 0.18 * swell,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
    );
  }
}

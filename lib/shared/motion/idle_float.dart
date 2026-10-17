import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/app_motion.dart';

/// A calm sign of life for an empty state: [child] drifts up and down by
/// [height] for two slow breaths after it appears, then rests (a loop would
/// draw 120 frames a second for as long as the screen stays empty). A
/// transform only; reduced motion: still.
class IdleFloat extends StatefulWidget {
  const IdleFloat({super.key, required this.child, this.height = 4});

  final Widget child;
  final double height;

  /// One breath: up, down, back.
  static const breath = Duration(milliseconds: 2400);

  @override
  State<IdleFloat> createState() => _IdleFloatState();
}

class _IdleFloatState extends State<IdleFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(vsync: this, duration: IdleFloat.breath * 2);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && !AppMotion.reduced(context)) {
      _started = true;
      _float.forward();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _float,
    child: widget.child,
    builder: (context, child) => Transform.translate(
      // Two full sine waves over the run; zero at both ends.
      offset: Offset(0, -widget.height * math.sin(_float.value * 4 * math.pi)),
      child: child,
    ),
  );
}

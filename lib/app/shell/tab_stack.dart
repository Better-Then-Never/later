import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../shared/motion/tint_painter.dart';

/// The main tabs: all kept alive (like [IndexedStack]), the hidden ones
/// with their tickers off, and the one coming in rising a little out of the
/// page background (MOTION_CATALOG.md, "Tabs").
///
/// Hidden tabs off: their animations stop, and their pictures no longer
/// rebuild each time a page opens or closes over the tabs (every [Image]
/// listens to [TickerMode], which flips for the whole shell then: 53
/// pictures, 3–4 ms at the start of each push and pop).
///
/// The fade is a cover in the background colour thinning over the tab (no
/// opacity layer, see `AppEnter`); reduced motion switches at once.
class TabStack extends StatefulWidget {
  const TabStack({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<TabStack> createState() => _TabStackState();
}

class _TabStackState extends State<TabStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _enter;
  late final Animation<double> _curve;

  /// How far below its place a tab starts.
  static const _rise = 6.0;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: AppMotion.fast,
      value: 1,
    );
    _curve = CurvedAnimation(parent: _enter, curve: AppMotion.enter);
  }

  @override
  void didUpdateWidget(TabStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index && !AppMotion.reduced(context)) {
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _rise * (1 - _curve.value)),
        child: child,
      ),
      child: CustomPaint(
        foregroundPainter: TintPainter(
          ReverseAnimation(_curve),
          context.palette.background,
        ),
        child: IndexedStack(
          index: widget.index,
          children: [
            for (var i = 0; i < widget.children.length; i++)
              TickerMode(enabled: i == widget.index, child: widget.children[i]),
          ],
        ),
      ),
    );
  }
}

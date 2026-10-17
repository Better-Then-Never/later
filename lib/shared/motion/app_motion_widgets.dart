import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';

/// Press feedback for buttons and tappable cards: scales down slightly while
/// pressed. The child keeps handling the tap; this only listens to pointers.
class AppPressable extends StatefulWidget {
  const AppPressable({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || AppMotion.reduced(context)) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressedScale : 1,
        duration: AppMotion.quick,
        curve: _pressed ? AppMotion.exit : AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}

/// Cross-fades between states (loading → content → empty/error). Give each
/// state's widget a distinct key.
class AppFadeSwitcher extends StatelessWidget {
  const AppFadeSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.fast),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      // Keep the outgoing state under the incoming one without resizing.
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      child: child,
    );
  }
}

/// Fades and lifts a widget in the first time it is built (a message that
/// just arrived, an item added to a list). Set [animate] to false for items
/// that were already there.
class AppEnter extends StatefulWidget {
  const AppEnter({super.key, required this.child, this.animate = true});

  final Widget child;
  final bool animate;

  @override
  State<AppEnter> createState() => _AppEnterState();
}

class _AppEnterState extends State<AppEnter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
    value: widget.animate ? 0 : 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

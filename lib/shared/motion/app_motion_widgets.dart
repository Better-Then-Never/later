import 'dart:async';

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
  const AppEnter({
    super.key,
    required this.child,
    this.animate = true,
    this.delay = Duration.zero,
  });

  final Widget child;
  final bool animate;

  /// Waits this long before coming in (rows of a list, one after another).
  final Duration delay;

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

  Timer? _wait;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _wait?.cancel();
      _controller.value = 1;
    } else if (_controller.value == 0 &&
        !_controller.isAnimating &&
        _wait == null) {
      if (widget.delay == Duration.zero) {
        _controller.forward();
      } else {
        _wait = Timer(widget.delay, () {
          if (mounted) _controller.forward();
        });
      }
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
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

/// Marks a list whose first rows come in one after another
/// ([AppStaggerItem]). Only rows built in the list's first moments animate:
/// rows that scroll in later, or change, simply appear.
class AppStaggerScope extends StatefulWidget {
  const AppStaggerScope({super.key, required this.child});

  final Widget child;

  @override
  State<AppStaggerScope> createState() => _AppStaggerScopeState();
}

class _AppStaggerScopeState extends State<AppStaggerScope> {
  final _shownAt = DateTime.now();

  @override
  Widget build(BuildContext context) =>
      _StaggerStart(shownAt: _shownAt, child: widget.child);
}

class _StaggerStart extends InheritedWidget {
  const _StaggerStart({required this.shownAt, required super.child});

  final DateTime shownAt;

  @override
  bool updateShouldNotify(_StaggerStart old) => old.shownAt != shownAt;
}

/// Row [index] of an [AppStaggerScope] list.
class AppStaggerItem extends StatelessWidget {
  const AppStaggerItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  /// Rows after this many come in with the last one.
  static const maxStaggered = 10;
  static const step = Duration(milliseconds: 35);
  static const _window = Duration(milliseconds: 600);

  @override
  Widget build(BuildContext context) {
    final start = context
        .dependOnInheritedWidgetOfExactType<_StaggerStart>()
        ?.shownAt;
    final fresh = start != null && DateTime.now().difference(start) < _window;
    return AppEnter(
      animate: fresh,
      delay: step * (index < maxStaggered ? index : maxStaggered),
      child: child,
    );
  }
}

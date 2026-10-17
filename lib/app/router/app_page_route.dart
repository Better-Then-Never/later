import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';

/// How a page enters: from the right (pages) or from the bottom (pages that
/// open like a sheet: the camera, "Add friends").
enum AppRouteAxis { horizontal, vertical }

/// The app's page route (MOTION_CATALOG.md, "Routes"). One motion for every
/// page, built to stay smooth on a real phone:
///
/// * the new page slides in (from the right, or from the bottom for
///   [AppRouteAxis.vertical]); the page under a horizontal push slides a
///   quarter to the left and dims. Only transforms and a painted scrim, never
///   opacity on a whole page: on Impeller a page-wide fade draws the page
///   offscreen every frame (10–13 ms raster frames, PERFORMANCE.md);
/// * interruptible: back during the push reverses from where it is;
/// * back swipe: a drag from the left edge of a horizontal page follows the
///   finger and pops on release past half the width or with a fling;
/// * reduced motion: no animation, the page is simply there.
class AppPageRoute<T> extends PageRoute<T> {
  AppPageRoute({
    required this.builder,
    this.axis = AppRouteAxis.horizontal,
    super.settings,
  });

  final WidgetBuilder builder;
  final AppRouteAxis axis;

  /// Width of the strip along the left edge where a back swipe starts.
  static const backSwipeEdge = 24.0;

  @override
  Duration get transitionDuration => AppMotion.emphasized;

  @override
  Duration get reverseTransitionDuration => AppMotion.standard;

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  /// The page underneath moves only for horizontal pushes; a vertical page
  /// dims it with its own scrim instead.
  @override
  bool canTransitionTo(TransitionRoute<dynamic> nextRoute) =>
      nextRoute is AppPageRoute && nextRoute.axis == AppRouteAxis.horizontal;

  /// The route's own animation, driven by the back swipe.
  AnimationController get _swipeController => controller!;

  /// A back swipe is in progress: the transition follows the finger
  /// linearly instead of the curve.
  bool get _swiping => navigator?.userGestureInProgress ?? false;

  bool get _canSwipeBack =>
      axis == AppRouteAxis.horizontal &&
      !isFirst &&
      !willHandlePopInternally &&
      popDisposition != RoutePopDisposition.doNotPop &&
      !(navigator?.userGestureInProgress ?? false) &&
      animation?.status == AnimationStatus.completed &&
      (secondaryAnimation?.isDismissed ?? true);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) {
      return axis == AppRouteAxis.horizontal
          ? _BackSwipe(route: this, child: child)
          : child;
    }
    // The page underneath dims to a share of the sheet scrim.
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = context.palette.scrim;
    final scrim = base.withValues(alpha: base.a * (dark ? 0.9 : 0.36));

    // This page leaving to the left under a new horizontal page.
    final under = _swiping
        ? secondaryAnimation
        : CurvedAnimation(
            parent: secondaryAnimation,
            curve: AppMotion.emphasizedCurve,
            reverseCurve: AppMotion.standardCurve,
          );
    Widget page = SlideTransition(
      position: Tween(
        begin: Offset.zero,
        end: const Offset(-0.25, 0),
      ).animate(under),
      child: _Scrim(animation: under, color: scrim, child: child),
    );

    // This page arriving.
    final arriving = _swiping
        ? animation
        : CurvedAnimation(
            parent: animation,
            curve: AppMotion.emphasizedCurve,
            reverseCurve: AppMotion.standardCurve,
          );
    if (axis == AppRouteAxis.horizontal) {
      page = SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(arriving),
        child: _EdgeShadow(
          child: _BackSwipe(route: this, child: page),
        ),
      );
    } else {
      page = SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(arriving),
        child: page,
      );
      // The page underneath dims while this one rises over it.
      page = Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(painter: _ScrimPainter(arriving, scrim)),
          ),
          page,
        ],
      );
    }
    return page;
  }
}

/// [page] as an [AppPageRoute] from the right.
Route<T> appRoute<T>(Widget page, {RouteSettings? settings}) =>
    AppPageRoute<T>(builder: (_) => page, settings: settings);

/// [page] as an [AppPageRoute] from the bottom (pages that open like a
/// sheet).
Route<T> appSheetRoute<T>(Widget page, {RouteSettings? settings}) =>
    AppPageRoute<T>(
      builder: (_) => page,
      axis: AppRouteAxis.vertical,
      settings: settings,
    );

/// A scrim painted over [child] as [animation] runs (no layer, no opacity).
class _Scrim extends StatelessWidget {
  const _Scrim({
    required this.animation,
    required this.color,
    required this.child,
  });

  final Animation<double> animation;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: _ScrimPainter(animation, color),
    child: child,
  );
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter(this.animation, this.color) : super(repaint: animation);

  final Animation<double> animation;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t <= 0) return;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = color.withValues(alpha: color.a * t),
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.animation != animation || old.color != color;
}

/// A soft shadow along the left edge of a page sliding in, drawn as a
/// gradient (a blurred shadow would be a filter pass every frame).
class _EdgeShadow extends StatelessWidget {
  const _EdgeShadow({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shadow = context.palette.shadowCard;
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        Positioned(
          left: -12,
          top: 0,
          bottom: 0,
          width: 12,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [shadow.withValues(alpha: 0), shadow],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// The back swipe: a horizontal drag that starts at the left edge moves the
/// page with the finger.
class _BackSwipe<T> extends StatefulWidget {
  const _BackSwipe({required this.route, required this.child});

  final AppPageRoute<T> route;
  final Widget child;

  @override
  State<_BackSwipe<T>> createState() => _BackSwipeState<T>();
}

class _BackSwipeState<T> extends State<_BackSwipe<T>> {
  late final HorizontalDragGestureRecognizer _drag =
      HorizontalDragGestureRecognizer(debugOwner: this)
        ..onStart = _start
        ..onUpdate = _update
        ..onEnd = _end
        ..onCancel = _cancel;
  bool _active = false;

  AnimationController get _controller => widget.route._swipeController;

  NavigatorState get _navigator => widget.route.navigator!;

  void _down(PointerDownEvent event) {
    if (widget.route._canSwipeBack) _drag.addPointer(event);
  }

  void _start(DragStartDetails details) {
    _active = true;
    _navigator.didStartUserGesture();
  }

  void _update(DragUpdateDetails details) {
    if (!_active) return;
    final width = context.size?.width ?? 1;
    _controller.value -= (details.primaryDelta ?? 0) / width;
  }

  void _end(DragEndDetails details) {
    if (!_active) return;
    final width = context.size?.width ?? 1;
    final velocity = details.velocity.pixelsPerSecond.dx / width;
    final pop = velocity > 1 || (velocity > -1 && _controller.value < 0.5);
    _finish(pop);
  }

  void _cancel() {
    if (_active) _finish(false);
  }

  void _finish(bool pop) {
    _active = false;
    if (pop) {
      _navigator.pop();
    } else {
      _controller.forward();
    }
    if (_controller.isAnimating) {
      late final AnimationStatusListener done;
      done = (status) {
        if (status.isAnimating) return;
        _navigator.didStopUserGesture();
        _controller.removeStatusListener(done);
      };
      _controller.addStatusListener(done);
    } else {
      _navigator.didStopUserGesture();
    }
  }

  @override
  void dispose() {
    _drag.dispose();
    if (_active) widget.route.navigator?.didStopUserGesture();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final edge =
        AppPageRoute.backSwipeEdge + MediaQuery.paddingOf(context).left;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: edge,
          child: Listener(
            onPointerDown: _down,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

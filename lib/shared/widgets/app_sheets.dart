import 'package:flutter/material.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';

/// The two ways the app opens something over a page (F-32), over the same
/// dimmed scrim (MOTION_CATALOG.md, "Sheets and cards"):
///
/// * [showCenteredSheet]: a card in the middle of the screen for menus,
///   confirmations, short forms and the capsule dialog ([AppCardRoute]): it
///   rises from below and settles; a tap outside or a drag down closes it;
///   the keyboard pushes it up.
/// * [showEdgeSheet]: a panel from the bottom edge for lists and threads,
///   built with [EdgeSheet] (rounded top, grab handle); dragging it down
///   closes it.
abstract final class AppSheets {
  /// Corner radius of every card and sheet.
  static const double radius = 25;

  /// Width of the centred cards (menus and confirmations).
  static const double cardWidth = 264;
}

Future<T?> showCenteredSheet<T>(BuildContext context, Widget child) =>
    Navigator.of(context).push(
      AppCardRoute<T>(
        builder: (_) => child,
        barrierColor: context.palette.scrim,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
      ),
    );

Future<T?> showEdgeSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: context.palette.scrim,
      sheetAnimationStyle: AppMotion.reduced(context)
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: AppMotion.emphasized,
              reverseDuration: AppMotion.standard,
              curve: AppMotion.emphasizedCurve,
              reverseCurve: AppMotion.standardCurve,
            ),
      builder: builder,
    );

/// A card over the page, centred, on a scrim: the route of
/// [showCenteredSheet] and of dialogs. A page route (not a popup), so a
/// [Hero] can fly into it. Enter: the card rises from below the screen and
/// settles from 96 % while the scrim darkens; no fade (an opacity layer the
/// size of the card every frame made the capsule dialog janky). Out: a tap
/// outside, back, or a drag down past a third of the card or with a flick.
/// Reduced motion: no animation.
class AppCardRoute<T> extends PageRoute<T> {
  AppCardRoute({
    required this.builder,
    required Color barrierColor,
    required String barrierLabel,
    super.settings,
  }) : _barrierColor = barrierColor,
       _barrierLabel = barrierLabel;

  final WidgetBuilder builder;
  final Color _barrierColor;
  final String _barrierLabel;

  @override
  Color? get barrierColor => _barrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => _barrierLabel;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => AppMotion.emphasized;

  @override
  Duration get reverseTransitionDuration => AppMotion.standard;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Material(
    // Text and fields on the card take the theme's styles (without it, a
    // title fell back to Flutter's yellow-underlined error style).
    type: MaterialType.transparency,
    child: Padding(
      // A card with a text field stays above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Center(child: _DragToClose(child: builder(context))),
    ),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final curve = CurvedAnimation(
      parent: animation,
      curve: AppMotion.emphasizedCurve,
      reverseCurve: AppMotion.exit,
    );
    // A rise only. Fading the card was an offscreen layer of the whole card
    // every frame (the capsule dialog went 20 % janky); scaling it made
    // Impeller draw its letters again at every new size (glyph atlas).
    final travel = MediaQuery.sizeOf(context).height * 0.6;
    return AnimatedBuilder(
      animation: curve,
      child: child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, travel * (1 - curve.value)),
        child: child,
      ),
    );
  }
}

/// Follows a downward drag on the card; past a third of its height, or on a
/// flick, the route closes; otherwise the card springs back.
class _DragToClose extends StatefulWidget {
  const _DragToClose({required this.child});

  final Widget child;

  @override
  State<_DragToClose> createState() => _DragToCloseState();
}

class _DragToCloseState extends State<_DragToClose>
    with SingleTickerProviderStateMixin {
  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  );
  double _dy = 0;
  double _from = 0;

  @override
  void initState() {
    super.initState();
    _back.addListener(() {
      setState(() => _dy = _from * (1 - AppMotion.exit.transform(_back.value)));
    });
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _update(DragUpdateDetails details) {
    _back.stop();
    setState(() => _dy = (_dy + details.delta.dy).clamp(0, double.infinity));
  }

  void _end(DragEndDetails details) {
    final height = context.size?.height ?? 1;
    if (_dy > height / 3 || details.velocity.pixelsPerSecond.dy > 700) {
      Navigator.of(context).maybePop();
      return;
    }
    _from = _dy;
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onVerticalDragUpdate: _update,
    onVerticalDragEnd: _end,
    child: Transform.translate(offset: Offset(0, _dy), child: widget.child),
  );
}

/// A [showEdgeSheet] panel: [height] tall, rounded top corners, the grab
/// handle on top of [child].
class EdgeSheet extends StatelessWidget {
  const EdgeSheet({
    super.key,
    required this.height,
    required this.child,
    this.color,
  });

  final double height;
  final Widget child;

  /// The page background when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color ?? context.palette.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSheets.radius),
        ),
      ),
      child: Column(
        children: [
          const SheetHandle(),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// The grab handle at the top of a sheet: it can be dragged down to close.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: context.palette.disabled,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

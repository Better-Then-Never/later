import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// The two ways the app opens something over a page (F-32), with the same
/// dimmed barrier and slide-up animation:
///
/// * [showCenteredSheet]: a card in the middle of the screen for menus,
///   confirmations and short forms; a tap outside closes it and the
///   keyboard pushes it up.
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
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: context.palette.scrim,
      builder: (context) => Padding(
        // A card with a text field stays above the keyboard.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: GestureDetector(onTap: () {}, child: child),
          ),
        ),
      ),
    );

Future<T?> showEdgeSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: context.palette.scrim,
      builder: builder,
    );

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

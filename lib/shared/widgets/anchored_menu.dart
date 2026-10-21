import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';

/// One choice of an [showAnchoredMenu] menu.
class AnchoredMenuItem<T> {
  const AnchoredMenuItem({
    required this.value,
    required this.label,
    this.danger = false,
    this.height = 44,
  });

  final T value;
  final String label;

  /// Red words: something that cannot be taken back (report, delete).
  final bool danger;
  final double height;
}

/// A small menu of the v2 design (Figma "Comment menu", "More menu"): a
/// surface card with 18 dp corners and the raised shadow, rows of 16 dp
/// words. It opens by [anchorContext]'s widget: [above] it, lined up with its
/// right edge (the ⋯ button, over a [scrim]), or at [offset] from its top
/// left corner (a long-pressed comment). Returns the chosen value, or null.
Future<T?> showAnchoredMenu<T>(
  BuildContext anchorContext, {
  required double width,
  required List<AnchoredMenuItem<T>> items,
  bool above = false,
  Offset offset = Offset.zero,
  bool scrim = false,
}) {
  final navigator = Navigator.of(anchorContext);
  final overlay = navigator.overlay!.context.findRenderObject()! as RenderBox;
  final box = anchorContext.findRenderObject()! as RenderBox;
  final anchor = box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  return navigator.push(
    _AnchoredMenuRoute<T>(
      anchor: anchor,
      width: width,
      items: items,
      above: above,
      offset: offset,
      barrierColor: scrim ? anchorContext.palette.scrim : Colors.transparent,
      barrierLabel: MaterialLocalizations.of(
        anchorContext,
      ).modalBarrierDismissLabel,
    ),
  );
}

class _AnchoredMenuRoute<T> extends PopupRoute<T> {
  _AnchoredMenuRoute({
    required this.anchor,
    required this.width,
    required this.items,
    required this.above,
    required this.offset,
    required Color barrierColor,
    required String barrierLabel,
  }) : _barrierColor = barrierColor,
       _barrierLabel = barrierLabel;

  final Rect anchor;
  final double width;
  final List<AnchoredMenuItem<T>> items;
  final bool above;
  final Offset offset;
  final Color _barrierColor;
  final String _barrierLabel;

  @override
  Color? get barrierColor => _barrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => _barrierLabel;

  @override
  Duration get transitionDuration => AppMotion.fast;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final media = MediaQuery.of(context);
    final height = items.fold<double>(12, (sum, item) => sum + item.height);
    final screen = media.size;
    const margin = 8.0;
    final left = above ? anchor.right - 4 - width : anchor.left + offset.dx;
    final top = above ? anchor.top - 4 - height : anchor.top + offset.dy;
    return Stack(
      children: [
        Positioned(
          left: left.clamp(
            margin,
            math.max(margin, screen.width - width - margin),
          ),
          top: top.clamp(
            media.padding.top + margin,
            math.max(
              media.padding.top + margin,
              screen.height - media.padding.bottom - height - margin,
            ),
          ),
          width: width,
          child: _AnchoredMenu<T>(items: items),
        ),
      ],
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppMotion.enter),
      child: child,
    );
  }
}

class _AnchoredMenu<T> extends StatelessWidget {
  const _AnchoredMenu({required this.items});

  final List<AnchoredMenuItem<T>> items;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.raised(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items)
              InkWell(
                onTap: () => Navigator.of(context).pop(item.value),
                child: Container(
                  height: item.height,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 16,
                      height: 1.25,
                      color: item.danger
                          ? AppColors.danger
                          : palette.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

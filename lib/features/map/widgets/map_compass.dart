import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/motion/app_motion_widgets.dart';

/// Shown above the zoom pill only while the map is turned: the needle points
/// north and a tap turns the map back. Google's own compass sat alone at the
/// top left (F-11); this one lives with the other controls.
class MapCompass extends StatelessWidget {
  const MapCompass({
    super.key,
    required this.bearing,
    required this.onTap,
    this.size = 52,
  });

  final ValueListenable<double> bearing;
  final VoidCallback onTap;
  final double size;

  /// A map turned less than this (either way) counts as facing north.
  static const _tolerance = 1.0;

  static bool isTurned(double degrees) {
    final d = degrees % 360;
    return d > _tolerance && d < 360 - _tolerance;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ValueListenableBuilder<double>(
      valueListenable: bearing,
      builder: (context, degrees, _) {
        final turned = isTurned(degrees);
        return IgnorePointer(
          ignoring: !turned,
          child: ExcludeSemantics(
            excluding: !turned,
            child: AnimatedScale(
              scale: turned ? 1 : 0,
              duration: AppMotion.of(context, AppMotion.standard),
              curve: turned ? AppMotion.enter : AppMotion.exit,
              child: Semantics(
                button: true,
                label: context.l10n.mapCompass,
                child: AppPressable(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: palette.surface,
                        shape: BoxShape.circle,
                        border: palette.isDark
                            ? Border.all(color: palette.cardBorder)
                            : null,
                        boxShadow: AppShadows.raised(context),
                      ),
                      child: CustomPaint(
                        painter: _NeedlePainter(
                          // The map turned clockwise by [degrees], so north
                          // on screen is that much anticlockwise.
                          angle: -degrees * math.pi / 180,
                          north: AppColors.brandGreen,
                          south: palette.iconMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NeedlePainter extends CustomPainter {
  const _NeedlePainter({
    required this.angle,
    required this.north,
    required this.south,
  });

  final double angle;
  final Color north;
  final Color south;

  @override
  void paint(Canvas canvas, Size size) {
    const half = 15.0;
    const width = 5.5;
    canvas
      ..translate(size.width / 2, size.height / 2)
      ..rotate(angle);
    final tip = Path()
      ..moveTo(0, -half)
      ..lineTo(width, 0)
      ..lineTo(-width, 0)
      ..close();
    final tail = Path()
      ..moveTo(0, half)
      ..lineTo(width, 0)
      ..lineTo(-width, 0)
      ..close();
    canvas
      ..drawPath(tip, Paint()..color = north)
      ..drawPath(tail, Paint()..color = south);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) =>
      old.angle != angle || old.north != north || old.south != south;
}

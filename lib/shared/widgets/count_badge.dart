import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text_styles.dart';

/// The app's red count pill (unread notifications, friend requests, unread
/// messages): a circle for one digit, a pill for more, "99+" above 99, and
/// nothing (no space) at 0. Scales in when it appears.
class CountBadge extends StatelessWidget {
  const CountBadge({
    super.key,
    required this.count,
    this.size = 20,
    this.color = AppColors.materialRed,
  });

  final int count;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.standard),
      curve: AppMotion.enter,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Container(
        height: size,
        constraints: BoxConstraints(minWidth: size),
        padding: count > 9
            ? EdgeInsets.symmetric(horizontal: size * 0.3)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        // Center with factor 1 keeps the pill as small as its text (a
        // Container `alignment` would stretch it to the available width).
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            count > 99 ? '99+' : '$count',
            semanticsLabel: '$count unread',
            style: TextStyle(
              color: AppColors.white,
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
              fontFamily: kAppFontFamily,
            ),
          ),
        ),
      ),
    );
  }
}

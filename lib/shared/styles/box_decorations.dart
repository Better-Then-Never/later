import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';

class BoxDecorations {
  /// The white card: radius 25 with the `card` shadow; in dark mode a dark
  /// surface with a hairline edge (shadows do not show on dark).
  static BoxDecoration whiteCard(
    BuildContext context, {
    double borderRadius = 25,
  }) {
    final palette = context.palette;
    return BoxDecoration(
      color: palette.surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: palette.isDark ? Border.all(color: palette.cardBorder) : null,
      boxShadow: [
        BoxShadow(
          color: palette.shadowCard,
          spreadRadius: 1,
          blurRadius: 9,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration greyCard(
    BuildContext context, {
    double borderRadius = 25,
  }) {
    return BoxDecoration(
      color: context.palette.surfaceMuted,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  /// The dark shade over the top of the profile photo (same in both themes:
  /// it sits on a picture).
  static BoxDecoration blackShadow() {
    return BoxDecoration(
      color: AppColors.mediaBlack,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: AppColors.mediaShade,
          spreadRadius: 15,
          blurRadius: 20,
          offset: Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration softBlackShadow(BuildContext context) {
    return BoxDecoration(
      boxShadow: [
        BoxShadow(
          color: context.palette.shadowCard,
          spreadRadius: 1,
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
      borderRadius: BorderRadius.circular(25),
    );
  }

  static BoxDecoration redWithBorderRadius({double borderRadius = 10}) {
    return BoxDecoration(
      color: AppColors.materialRed,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  static BoxDecoration lightBlueInfo(BuildContext context) {
    final palette = context.palette;
    return BoxDecoration(
      color: palette.infoCardFill,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: palette.infoCardBorder, width: 1),
    );
  }

  static BoxDecoration defaultBorderRadius({
    Color color = AppColors.brandGreen,
  }) {
    return BoxDecoration(color: color, borderRadius: BorderRadius.circular(25));
  }
}

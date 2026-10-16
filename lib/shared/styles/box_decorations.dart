import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BoxDecorations {
  static BoxDecoration whiteCard({double borderRadius = 25}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          spreadRadius: 1,
          blurRadius: 9,
          offset: Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration greyCard({double borderRadius = 25}) {
    return BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  static BoxDecoration blackShadow() {
    return BoxDecoration(
      color: const Color.fromARGB(255, 0, 0, 0),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(120),
          spreadRadius: 15,
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  static BoxDecoration softBlackShadow() {
    return BoxDecoration(
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          spreadRadius: 1,
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
      borderRadius: BorderRadius.circular(25),
    );
  }

  static BoxDecoration redWithBorderRadius({double borderRadius = 10}) {
    return BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  static BoxDecoration lightBlueInfo() {
    return BoxDecoration(
      color: Colors.blue.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.blue.withValues(alpha: 0.3), width: 1),
    );
  }

  static BoxDecoration defaultBorderRadius({
    Color color = AppColors.brandGreen,
  }) {
    return BoxDecoration(color: color, borderRadius: BorderRadius.circular(25));
  }
}

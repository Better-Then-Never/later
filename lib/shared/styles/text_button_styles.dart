import 'package:flutter/material.dart';
import 'package:later/core/theme/app_colors.dart';

class TextButtonStyles {
  static ButtonStyle profileTextButtonStyle() {
    return TextButton.styleFrom(
      alignment: Alignment.centerLeft,
      foregroundColor: AppColors.black,
      textStyle: const TextStyle(fontSize: 16),
      splashFactory: NoSplash.splashFactory,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      overlayColor: Colors.transparent,
    );
  }
}

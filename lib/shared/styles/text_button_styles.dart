import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

class TextButtonStyles {
  static ButtonStyle profileTextButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      alignment: Alignment.centerLeft,
      foregroundColor: context.palette.textPrimary,
      textStyle: const TextStyle(fontSize: 16),
      splashFactory: NoSplash.splashFactory,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      overlayColor: Colors.transparent,
    );
  }
}

import 'package:flutter/material.dart';

class TextButtonStyles {
  static ButtonStyle profileTextButtonStyle() {
    return TextButton.styleFrom(
      alignment: Alignment.centerLeft,
      foregroundColor: Colors.black,
      textStyle: const TextStyle(fontSize: 16),
      splashFactory: NoSplash.splashFactory,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      overlayColor: Colors.transparent,
    );
  }
}

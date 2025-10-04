import 'package:flutter/material.dart';

class ElevatedButtonStyles {
  static ButtonStyle roundedButtonStyle({
    required Color color,
    Color? foregroundColor,
    double borderRadius = 25,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: foregroundColor ?? null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      elevation: 0,
    );
  }

  static ButtonStyle cancelButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.red,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      elevation: 0,
    );
  }
}

import 'package:flutter/material.dart';

import 'app_text_styles.dart';

abstract final class AppTheme {
  /// The original theme: Material 3 seeded from `Colors.green` with the app
  /// font. Component colours are applied by the shared widgets, not by the
  /// theme, because the seeded defaults are visible in a few places (button
  /// surface tint, switch colours) and must stay as they are.
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.light,
    ),
    fontFamily: kAppFontFamily,
  );
}

import 'package:flutter/material.dart';

import 'app_palette.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  /// The original theme: Material 3 seeded from `Colors.green` with the app
  /// font. Component colours are applied by the shared widgets, not by the
  /// theme, because the seeded defaults are visible in a few places (button
  /// surface tint, switch colours) and must stay as they are. The palette
  /// extension carries the colours that differ in dark mode.
  static ThemeData get light => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.light,
    ),
    fontFamily: kAppFontFamily,
    extensions: const [AppPalette.light],
  );

  /// The same theme for dark mode (DECISIONS.md D-03): the seeded dark scheme
  /// with the app's dark palette for pages, cards and text.
  static ThemeData get dark {
    const palette = AppPalette.dark;
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      ).copyWith(surface: palette.surface, onSurface: palette.textPrimary),
      fontFamily: kAppFontFamily,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.surface,
      dividerColor: palette.divider,
      extensions: const [palette],
    );
  }
}

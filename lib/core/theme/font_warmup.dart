import 'dart:ui' as ui;

import 'app_text_styles.dart';

/// Lays out one line of every script and weight the app shows, before the
/// first frame. The first text in a new weight, or in a script the app font
/// lacks (Inria Sans has no Cyrillic, so Russian falls back to the phone's
/// font), loads and shapes a font file: 5–10 ms that otherwise landed on the
/// first frame of a page or a chat (docs/feel/PERFORMANCE.md).
abstract final class FontWarmup {
  /// Latin, Cyrillic, Polish, German and Spanish letters, digits, and the
  /// emoji the reactions use.
  static const _sample =
      'Later Ag 0123 Привет Ёё ąęłńóśźż ÄÖÜß ñáé ❤️😂😮😢🔥👏';

  static void run() {
    for (final weight in const [ui.FontWeight.w400, ui.FontWeight.w700]) {
      for (final style in const [ui.FontStyle.normal, ui.FontStyle.italic]) {
        final builder = ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontFamily: kAppFontFamily,
            fontWeight: weight,
            fontStyle: style,
            fontSize: 14,
          ),
        )..addText(_sample);
        builder.build().layout(const ui.ParagraphConstraints(width: 2000));
      }
    }
  }
}

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'app_text_styles.dart';

/// Fills the renderer's glyph atlas ahead of time. The first time a letter
/// is drawn at a new size, Impeller rasterises it into its atlas and
/// uploads the atlas (`UpdateAtlasBitmap`): 7–9 ms on the raster thread,
/// and it happened in the first frames of opening Settings or a capsule
/// (its reaction emoji), mid-animation (docs/feel/PERFORMANCE.md).
///
/// [schedule] draws, offscreen and a little at a time over idle frames
/// after the home screen settles, the letters, digits and emoji the app
/// shows, at the sizes it mostly uses on a 360 dp wide phone. Glyphs drawn
/// offscreen land in the same atlas as the screen's.
abstract final class GlyphWarmup {
  static const _letters =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
      'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя'
      '.,:;!?@#%&()+-–—«»"\'/·…×';

  /// Reaction emoji and the sizes they appear at.
  static const _emoji = '❤️😂😮😢🔥👏';
  static const _emojiSizes = [14.0, 18.0, 20.0];

  /// (size, bold) pairs: the fixed sizes used most, and the screen-relative
  /// ones (`width * 0.045` etc.) on a 360 dp wide screen.
  static const _styles = [
    (12.0, false),
    (13.0, false),
    (14.0, false),
    (14.0, true),
    (16.0, false),
    (16.0, true),
    (18.0, true),
    (17.0, false),
    (16.2, true),
    (14.4, false),
    (18.0, false),
    (12.6, false),
    (20.0, true),
    (32.0, true),
  ];

  static bool _started = false;

  /// Starts the warm-up [delay] after now, one style per idle frame.
  static void schedule({Duration delay = const Duration(seconds: 2)}) {
    if (_started) return;
    _started = true;
    unawaited(
      Future<void>.delayed(delay, () async {
        final ratio = WidgetsBinding
            .instance
            .platformDispatcher
            .implicitView
            ?.devicePixelRatio;
        if (ratio == null) return;
        for (final (size, bold) in _styles) {
          await SchedulerBinding.instance.endOfFrame;
          _draw(_letters, size, bold, ratio);
        }
        for (final size in _emojiSizes) {
          await SchedulerBinding.instance.endOfFrame;
          _draw(_emoji, size, false, ratio);
        }
      }),
    );
  }

  static void _draw(String text, double size, bool bold, double ratio) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        fontFamily: kAppFontFamily,
        fontSize: size,
        fontWeight: bold ? ui.FontWeight.w700 : ui.FontWeight.w400,
      ),
    )..addText(text);
    const width = 360.0;
    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: width));
    final recorder = ui.PictureRecorder();
    // At the screen's scale, so the glyphs are the ones the screen needs.
    ui.Canvas(recorder)
      ..scale(ratio)
      ..drawParagraph(paragraph, ui.Offset.zero);
    final picture = recorder.endRecording();
    // Big enough to hold the text, so nothing is culled before it reaches
    // the atlas; disposed at once.
    final image = picture.toImageSync(
      (width * ratio).ceil(),
      (paragraph.height * ratio).ceil(),
    );
    image.dispose();
    picture.dispose();
    paragraph.dispose();
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/capsule.dart';
import '../marker_icons.dart';
import '../selected_pin.dart';

/// The pictures the MapLibre map draws its markers with (PNG at the screen's
/// density; the map is told the density, so 1 is their size in dp).
abstract final class MapLibreImages {
  /// What a bubble says: the count, or "99+" (labels for 2 to 100 are drawn).
  static String bubbleLabel(int count) => count > 99 ? '99+' : '$count';

  /// Every picture by its name in the style: `pin_<colour>`, `shadow`,
  /// `bubble_<label>`, `me`. A selected pin is its pin grown by the layer.
  static Future<Map<String, Uint8List>> all({
    required double ratio,
    required bool dark,
  }) async {
    final out = <String, Uint8List>{};
    for (final color in CapsuleColor.values) {
      final pin =
          MarkerIcons.pinPicture(color) ??
          await _decode(
            AppIcons.mapPin(color.name),
            (SelectedPin.side * ratio).round(),
          );
      out['pin_${color.name}'] = await _png(pin);
    }
    out['shadow'] = await _shadow(ratio);
    for (var n = 2; n <= 100; n++) {
      out['bubble_${bubbleLabel(n)}'] = await _bubble(bubbleLabel(n), ratio);
    }
    final user = dark
        ? AppIcons.mapPinUser.replaceFirst(
            AppAssetDirs.icons,
            AppAssetDirs.iconsDark,
          )
        : AppIcons.mapPinUser;
    out['me'] = await _png(await _decode(user, (64 * ratio).round()));
    return out;
  }

  static Future<ui.Image> _decode(String asset, int width) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    return (await codec.getNextFrame()).image;
  }

  static Future<Uint8List> _png(ui.Image image) async =>
      (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();

  /// The soft oval under the selected, floating pin.
  static Future<Uint8List> _shadow(double ratio) {
    final w = 30 * ratio, h = 12 * ratio;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h / 2),
        width: 18 * ratio,
        height: 5.5 * ratio,
      ),
      Paint()
        ..color = AppColors.mediaBlack.withValues(alpha: 0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.5 * ratio),
    );
    return _record(recorder, w, h);
  }

  /// A numbered bubble: a brand-green disc in a white ring over a soft
  /// shadow, the count in white bold. Bigger than the Google map's (D-24
  /// asked for legible numbers): 17 dp text on a 38 to 50 dp disc; the map
  /// scales it further by the count.
  static Future<Uint8List> _bubble(String text, double ratio) {
    final diameter =
        switch (text.length) {
          1 => 38.0,
          2 => 44.0,
          _ => 50.0,
        } *
        ratio;
    final size = diameter + 8 * ratio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    canvas
      ..drawCircle(
        center.translate(0, 1.5 * ratio),
        diameter / 2,
        Paint()
          ..color = AppColors.mediaBlack.withValues(alpha: 0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * ratio),
      )
      ..drawCircle(center, diameter / 2, Paint()..color = AppColors.onAccent)
      ..drawCircle(
        center,
        diameter / 2 - 2.5 * ratio,
        Paint()..color = AppColors.brandGreen,
      );
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: kAppFontFamily,
          fontSize: 17 * ratio,
          fontWeight: FontWeight.bold,
          color: AppColors.onAccent,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
    painter.dispose();
    return _record(recorder, size, size);
  }

  static Future<Uint8List> _record(
    ui.PictureRecorder recorder,
    double w,
    double h,
  ) async {
    final image = await recorder.endRecording().toImage(
      math.max(1, w.ceil()),
      math.max(1, h.ceil()),
    );
    return _png(image);
  }
}

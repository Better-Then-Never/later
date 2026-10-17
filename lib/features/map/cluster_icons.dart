import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// The numbered bubbles of capsule clusters: a brand-green disc in a white
/// ring, the count in white. Each label is drawn once per app run and kept,
/// so a camera stop costs no drawing.
abstract final class ClusterIcons {
  static final Map<String, Future<BitmapDescriptor>> _cache = {};

  /// What the bubble says: the count, or "99+".
  static String label(int count) => count > 99 ? '99+' : '$count';

  static Future<BitmapDescriptor> forCount(int count, double pixelRatio) {
    final text = label(count);
    return _cache['$text@$pixelRatio'] ??= _draw(text, pixelRatio);
  }

  static Future<BitmapDescriptor> _draw(String text, double ratio) async {
    final diameter = switch (text.length) {
      1 => 34.0,
      2 => 40.0,
      _ => 46.0,
    };
    final size = diameter * ratio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    canvas
      ..drawCircle(center, size / 2, Paint()..color = AppColors.onAccent)
      ..drawCircle(
        center,
        size / 2 - 2.5 * ratio,
        Paint()..color = AppColors.brandGreen,
      );
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: kAppFontFamily,
          fontSize: 15 * ratio,
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
    final image = await recorder.endRecording().toImage(
      size.ceil(),
      size.ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: ratio,
    );
  }
}

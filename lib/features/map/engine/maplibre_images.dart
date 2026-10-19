import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/logging/app_logger.dart';
import '../../settings/app_info.dart';
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
  /// Bump when a picture is drawn differently or its artwork changes (a new
  /// app version renews the cache by itself).
  static const drawing = 1;

  /// [all], from this phone's cache when drawn before for this density,
  /// theme, drawing and app version: drawing them took 0.5 s of every cold
  /// start (docs/map/COLD_START.md). Nothing personal: the same pictures for
  /// everyone.
  static Future<Map<String, Uint8List>> cached({
    required double ratio,
    required bool dark,
    Future<Directory> Function()? directory,
  }) async {
    File? file;
    try {
      final app = await AppInfo.load();
      final dir = await (directory ?? _defaultDirectory)();
      final key =
          '${ratio.toStringAsFixed(2)}_${dark ? 'dark' : 'light'}_d$drawing'
          '_${app.version}+${app.build}';
      file = File(
        '${dir.path}/${key.replaceAll(RegExp(r'[^\w.+-]'), '_')}.bin',
      );
      if (await file.exists()) {
        final images = decode(await file.readAsBytes());
        if (images.length == count) return images;
      }
    } on Object catch (e) {
      AppLogger.warning('Map pictures not read', error: e);
    }
    final images = await all(ratio: ratio, dark: dark);
    if (file != null) unawaited(_keep(file, images));
    return images;
  }

  /// How many pictures [all] draws: the pins, the shadow, the bubbles, me.
  static final count = CapsuleColor.values.length + 1 + 99 + 1;

  static Future<Directory> _defaultDirectory() async =>
      Directory('${(await getApplicationSupportDirectory()).path}/map_images');

  /// Only the newest set stays.
  static Future<void> _keep(File file, Map<String, Uint8List> images) async {
    try {
      final dir = file.parent;
      if (await dir.exists()) {
        await for (final old in dir.list()) {
          if (old is File && old.path != file.path) await old.delete();
        }
      } else {
        await dir.create(recursive: true);
      }
      final part = File('${file.path}.part');
      await part.writeAsBytes(encode(images), flush: true);
      await part.rename(file.path);
    } on Object catch (e) {
      AppLogger.warning('Map pictures not kept', error: e);
    }
  }

  static const _magic = 0x4C4D4901;

  /// The pictures as bytes: magic, count, then each name and PNG.
  static Uint8List encode(Map<String, Uint8List> images) {
    final out = BytesBuilder(copy: false)
      ..add(
        (ByteData(8)
              ..setUint32(0, _magic)
              ..setUint32(4, images.length))
            .buffer
            .asUint8List(),
      );
    for (final MapEntry(:key, :value) in images.entries) {
      final name = utf8.encode(key);
      out
        ..add((ByteData(2)..setUint16(0, name.length)).buffer.asUint8List())
        ..add(name)
        ..add((ByteData(4)..setUint32(0, value.length)).buffer.asUint8List())
        ..add(value);
    }
    return out.takeBytes();
  }

  /// [encode]'s pictures; empty when the bytes are anything else.
  static Map<String, Uint8List> decode(Uint8List bytes) {
    try {
      final data = ByteData.sublistView(bytes);
      if (data.getUint32(0) != _magic) return const {};
      final images = <String, Uint8List>{};
      var at = 8;
      for (var i = data.getUint32(4); i > 0; i--) {
        final nameLength = data.getUint16(at);
        final name = utf8.decode(
          Uint8List.sublistView(bytes, at + 2, at + 2 + nameLength),
        );
        at += 2 + nameLength;
        final length = data.getUint32(at);
        images[name] = Uint8List.sublistView(bytes, at + 4, at + 4 + length);
        at += 4 + length;
      }
      return images;
    } on Object {
      return const {};
    }
  }

  /// All drawn at once: one after another, each waiting for its raster,
  /// they took 1.75 s at a cold start (docs/map/COLD_START.md).
  static Future<Map<String, Uint8List>> all({
    required double ratio,
    required bool dark,
  }) async {
    Future<MapEntry<String, Uint8List>> named(
      String name,
      Future<Uint8List> png,
    ) async => MapEntry(name, await png);
    return Map.fromEntries(
      await Future.wait([
        for (final color in CapsuleColor.values)
          named('pin_${color.name}', _pin(color, ratio)),
        named('shadow', _shadow(ratio)),
        for (var n = 2; n <= 100; n++)
          named('bubble_${bubbleLabel(n)}', _bubble(bubbleLabel(n), ratio)),
        named('me', _me(dark: dark, ratio: ratio)),
      ]),
    );
  }

  static Future<Uint8List> _pin(CapsuleColor color, double ratio) async => _png(
    MarkerIcons.pinPicture(color) ??
        await _decode(
          AppIcons.mapPin(color.name),
          (SelectedPin.side * ratio).round(),
        ),
  );

  static Future<Uint8List> _me({
    required bool dark,
    required double ratio,
  }) async {
    final user = dark
        ? AppIcons.mapPinUser.replaceFirst(
            AppAssetDirs.icons,
            AppAssetDirs.iconsDark,
          )
        : AppIcons.mapPinUser;
    return _png(await _decode(user, (64 * ratio).round()));
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

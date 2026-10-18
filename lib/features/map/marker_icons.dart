import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/assets/app_assets.dart';
import '../../core/logging/app_logger.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/capsule.dart';
import 'selected_pin.dart';

/// Map marker bitmaps, decoded once per app run. Loading them before the
/// first markers are built removes the null-check crash on `_capsuleIcons[..]!`
/// (BUG-042); an unknown colour falls back to red.
class MarkerIcons {
  MarkerIcons._(this._capsules, this.user);

  final Map<CapsuleColor, BitmapDescriptor> _capsules;
  final BitmapDescriptor user;

  BitmapDescriptor forColor(CapsuleColor color) =>
      _capsules[color] ?? _capsules[CapsuleColor.red]!;

  /// The frames of a selected pin of [color] ([SelectedPin.frames]); null
  /// until drawn (they are drawn in the background once per run, right after
  /// the pins load).
  List<BitmapDescriptor>? selectedFrames(CapsuleColor color) =>
      _selected[color];

  static final Map<CapsuleColor, List<BitmapDescriptor>> _selected = {};
  static Future<void>? _drawingSelected;

  /// Logical size of a pin (as the asset is shown).
  static const pinSize = 48.0;
  static const _pixelRatio = 3.0;

  /// The pin artwork's tip in its 457 px square (where it touches the map).
  static const _art = 457.0;
  static const _tipY = 420.0;

  static Future<void> _drawSelected() async {
    for (final color in CapsuleColor.values) {
      try {
        final data = await rootBundle.load(AppIcons.mapPin(color.name));
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final pin = (await codec.getNextFrame()).image;
        _selected[color] = [
          for (final f in SelectedPin.frames)
            BitmapDescriptor.bytes(
              await _frame(pin, f.scale, f.lift, f.shadow),
              width: SelectedPin.width,
              height: SelectedPin.height,
            ),
        ];
      } catch (e) {
        // Without frames the selected pin simply stays as it is.
        AppLogger.debug('Selected pin frames for ${color.name} failed: $e');
      }
    }
  }

  /// One frame: a soft shadow on the spot (where the marker is anchored)
  /// and the pin grown by [scale], its tip [lift] dp above the spot; the
  /// shadow of [shadow] strength is smaller the higher the pin floats.
  static Future<Uint8List> _frame(
    ui.Image pin,
    double scale,
    double lift,
    double shadow,
  ) {
    const w = SelectedPin.width * _pixelRatio;
    const h = SelectedPin.height * _pixelRatio;
    const spotY = h - SelectedPin.shadowFromBottom * _pixelRatio;
    final side = pinSize * scale * _pixelRatio;
    final tipY = spotY - lift * _pixelRatio;
    final dst = Rect.fromLTWH(
      (w - side) / 2,
      tipY - _tipY / _art * side,
      side,
      side,
    );
    final shadowWidth = (22 - lift * 0.5) * _pixelRatio;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: const Offset(w / 2, spotY),
          width: shadowWidth,
          height: shadowWidth * 0.32,
        ),
        Paint()
          ..color = AppColors.mediaBlack.withValues(alpha: shadow)
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.normal,
            2.5 * _pixelRatio,
          ),
      )
      ..drawImageRect(
        pin,
        Rect.fromLTWH(0, 0, pin.width.toDouble(), pin.height.toDouble()),
        dst,
        Paint()..filterQuality = FilterQuality.medium,
      );
    return recorder
        .endRecording()
        .toImage(w.round(), h.round())
        .then((image) => image.toByteData(format: ui.ImageByteFormat.png))
        .then((bytes) => bytes!.buffer.asUint8List());
  }

  /// The capsule pins, one set shared by both themes. Markers are rebuilt
  /// only when this changes: new pins for every capsule after a theme switch
  /// re-sent all of them to the map, whose updates run on Android's main
  /// thread, where Flutter's vsync comes from (a 10 s freeze with 1,200
  /// capsules; docs/feel/PERFORMANCE.md).
  Object get capsulePins => _capsules;

  static final Map<bool, Future<MarkerIcons>> _loading = {};
  static Future<Map<CapsuleColor, BitmapDescriptor>>? _pins;

  /// Markers are drawn by the map itself, outside the themed asset bundle:
  /// in [dark] mode the user's figure comes from the dark icon set (a white
  /// figure; the black one vanished on the dark map). Capsule pins keep their
  /// white faces in both themes.
  static Future<MarkerIcons> load({bool dark = false}) =>
      _loading[dark] ??= _load(dark).then((icons) {
        // In the background, after the pins: ready before the first tap.
        _drawingSelected ??= _drawSelected();
        return icons;
      });

  static Future<Map<CapsuleColor, BitmapDescriptor>> _loadPins() async {
    final capsules = <CapsuleColor, BitmapDescriptor>{};
    for (final color in CapsuleColor.values) {
      capsules[color] = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        AppIcons.mapPin(color.name),
      );
    }
    return capsules;
  }

  static Future<MarkerIcons> _load(bool dark) async {
    final capsules = await (_pins ??= _loadPins());
    final user = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(64, 64)),
      dark
          ? AppIcons.mapPinUser.replaceFirst(
              AppAssetDirs.icons,
              AppAssetDirs.iconsDark,
            )
          : AppIcons.mapPinUser,
    );
    return MarkerIcons._(capsules, user);
  }
}

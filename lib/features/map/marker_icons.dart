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

  /// The grown pin of [color] and the shadow under it, for the map to draw
  /// a floating pin while it moves ([SelectedPin.apply]); null until drawn
  /// (in the background once per run, right after the pins load).
  BitmapDescriptor? selectedPin(CapsuleColor color) => _selectedPins[color];
  BitmapDescriptor? get selectedShadow => _selectedShadow;

  static final Map<CapsuleColor, BitmapDescriptor> _selectedPins = {};
  static BitmapDescriptor? _selectedShadow;
  static Future<void>? _drawingSelected;
  static const _pixelRatio = 3.0;

  static Future<void> _drawSelected() async {
    try {
      _selectedShadow = BitmapDescriptor.bytes(
        await _shadow(),
        width: SelectedPin.shadowWidth,
        height: SelectedPin.shadowHeight,
      );
    } catch (e) {
      AppLogger.debug('Selected pin shadow failed: $e');
    }
    for (final color in CapsuleColor.values) {
      try {
        final data = await rootBundle.load(AppIcons.mapPin(color.name));
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final pin = (await codec.getNextFrame()).image;
        _selectedPins[color] = BitmapDescriptor.bytes(
          await _pin(pin),
          width: SelectedPin.pinSide,
          height: SelectedPin.pinHeight,
        );
      } catch (e) {
        // Without it the map shows the plain pin while it moves.
        AppLogger.debug('Selected pin for ${color.name} failed: $e');
      }
    }
  }

  /// The grown pin at the top of a taller bitmap: the empty room below lets
  /// the anchor lift it off its spot.
  static Future<Uint8List> _pin(ui.Image pin) {
    const side = SelectedPin.pinSide * _pixelRatio;
    const height = SelectedPin.pinHeight * _pixelRatio;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      pin,
      Rect.fromLTWH(0, 0, pin.width.toDouble(), pin.height.toDouble()),
      const Rect.fromLTWH(0, 0, side, side),
      Paint()..filterQuality = FilterQuality.medium,
    );
    return _png(recorder, side, height);
  }

  /// The soft oval under a hovering pin, as the overlay draws it.
  static Future<Uint8List> _shadow() {
    const w = SelectedPin.shadowWidth * _pixelRatio;
    const h = SelectedPin.shadowHeight * _pixelRatio;
    const k = 1 - SelectedPin.hoverLift / 40;
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawOval(
      Rect.fromCenter(
        center: const Offset(w / 2, h / 2),
        width: 20 * k * _pixelRatio,
        height: 6 * k * _pixelRatio,
      ),
      Paint()
        ..color = AppColors.mediaBlack.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          2.5 * _pixelRatio,
        ),
    );
    return _png(recorder, w, h);
  }

  static Future<Uint8List> _png(
    ui.PictureRecorder recorder,
    double w,
    double h,
  ) => recorder
      .endRecording()
      .toImage(w.round(), h.round())
      .then((image) => image.toByteData(format: ui.ImageByteFormat.png))
      .then((bytes) => bytes!.buffer.asUint8List());

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

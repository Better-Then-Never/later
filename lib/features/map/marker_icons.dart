import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/assets/app_assets.dart';
import '../../data/models/capsule.dart';

/// Map marker bitmaps, decoded once per app run. Loading them before the
/// first markers are built removes the null-check crash on `_capsuleIcons[..]!`
/// (BUG-042); an unknown colour falls back to red.
class MarkerIcons {
  MarkerIcons._(this._capsules, this.user);

  final Map<CapsuleColor, BitmapDescriptor> _capsules;
  final BitmapDescriptor user;

  BitmapDescriptor forColor(CapsuleColor color) =>
      _capsules[color] ?? _capsules[CapsuleColor.red]!;

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
      _loading[dark] ??= _load(dark);

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

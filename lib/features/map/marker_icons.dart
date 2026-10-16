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

  static Future<MarkerIcons>? _loading;

  static Future<MarkerIcons> load() => _loading ??= _load();

  static Future<MarkerIcons> _load() async {
    final capsules = <CapsuleColor, BitmapDescriptor>{};
    for (final color in CapsuleColor.values) {
      capsules[color] = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        AppIcons.mapPin(color.name),
      );
    }
    final user = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(64, 64)),
      AppIcons.mapPinUser,
    );
    return MarkerIcons._(capsules, user);
  }
}

import 'package:flutter/material.dart';

/// Colours that are the same in light and dark: brand and accent colours,
/// and content drawn on them or on photos. Everything that changes with the
/// theme (surfaces, text, greys, dividers, shadows) is in AppPalette
/// (`context.palette`). Values reproduce the original design exactly (see
/// docs/refactor/DESIGN_SPEC.md §2); do not "tidy" them.
abstract final class AppColors {
  // Brand and accents
  static const brandGreen = Color(0xFF56C92E);
  static const placeYellow = Color(0xFFFFD900);
  static const danger = Color(0xFFFD4140);
  static const materialRed = Color(0xFFF44336);
  static const redAccent = Color(0xFFFF5252);
  static const errorPopup = Color(0xFFFF5757);
  static const infoBlue = Color(0xFF2196F3);
  static const viewProfileBlue = Color(0xFF3690FF);
  static const neutralButton = Color(0xFF6C757D);
  static const pendingYellow = Color(0xFFFDDB07);
  static const warningOrange = Color(0xFFFF9800);

  // Content on colour and on photos: the same in light and dark.
  /// Text and icons on brand green, danger red, info blue.
  static const onAccent = Color(0xFFFFFFFF);

  /// Text and icons drawn over photos and the camera preview.
  static const onMedia = Color(0xFFFFFFFF);
  static const onMediaMuted = Color(0xB3FFFFFF);

  /// Dark veils over photos (gradients, captions, the camera).
  static const mediaScrim = Color(0x73000000);
  static const mediaScrimStrong = Color(0xDD000000);
  static const mediaBlack = Color(0xFF000000);
  static const mediaShade = Color(0x78000000);

  /// Darker shades of [infoBlue] for text on its tinted cards.
  static const infoBlue600 = Color(0xFF1E88E5);
  static const infoBlue700 = Color(0xFF1976D2);
}

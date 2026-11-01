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

  // The capsule colours as the pins draw them (assets/icons/map/pin_*.png).
  static const capsuleRed = Color(0xFFF84038);
  static const capsuleBlue = Color(0xFF38A8F8);
  static const capsuleGreen = Color(0xFF50C028);
  static const capsuleYellow = Color(0xFFF8C830);
  static const capsuleOrange = Color(0xFFF09038);
  static const capsulePurple = Color(0xFFC038E8);
  static const materialRed = Color(0xFFF44336);
  static const redAccent = Color(0xFFFF5252);
  static const errorPopup = Color(0xFFFF5757);
  static const infoBlue = Color(0xFF2196F3);
  static const viewProfileBlue = Color(0xFF3690FF);
  static const neutralButton = Color(0xFF6C757D);
  static const pendingYellow = Color(0xFFFDDB07);
  static const warningOrange = Color(0xFFFF9800);

  // The passport (Figma Foundations: passport/paper, passport/ink): a
  // printed booklet, the same in light and dark.
  static const passportPaper = Color(0xFFF3EBD6);
  static const passportInk = Color(0xFF5E553F);

  /// The leather of the booklet (Figma passport/cover); also a stamp colour
  /// ("Forest").
  static const passportCover = Color(0xFF1E4A2D);
  static const passportText = Color(0xFF000000);
  static const passportShadow = Color(0x2E000000);

  // Content on colour and on photos: the same in light and dark.
  /// Text and icons on brand green, danger red, info blue.
  static const onAccent = Color(0xFFFFFFFF);

  // The MapLibre map's ground (assets/map/style_*.json, the Google map's
  // palette): shown until the map has drawn, so a cold start has no white.
  static const mapGroundLight = Color(0xFFF3F3F0);
  static const mapGroundDark = Color(0xFF1B1B1B);

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

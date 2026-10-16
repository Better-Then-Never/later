import 'package:flutter/material.dart';

/// Every colour used by the app. Values reproduce the original design exactly
/// (see docs/refactor/DESIGN_SPEC.md §2); do not "tidy" them.
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

  // Surfaces
  static const pageBackground = Color(0xFFF6F6F6);
  static const pageBackgroundAlt = Color(0xFFF5F5F5);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFEAEAEA);
  static const pill = Color(0xD9D9D9D9);
  static const divider = Color(0xFFD3D3D3);
  static const emptyAvatar = Color(0xFFDFDFDF);
  static const emptyBackground = Color(0xFFBBBBBB);
  static const placeholderGrey = Color(0xFFE0E0E0);
  static const iconGrey = Color(0xFF9E9E9E);
  static const popupDefault = Color(0xFF424242);

  // Text
  static const textPrimary = Colors.black;
  static const textSecondary = Color(0xFF5E5E5E);
  static const textTertiary = Color(0xFF6A6A6A);
  static const textMuted = Color(0xFF757575);
  static const textFaint = Color(0x8A000000);
  static const textOnPrimary = Colors.white;

  // Selection / status
  static const selectedNotification = Color(0xFFBBDEFB);
  static const unreadNotification = Color(0xFFE3F2FD);
  static const selectedCapsule = Color(0x6467CFFF);
  static const infoCardFill = Color(0x1A2196F3);
  static const infoCardBorder = Color(0x4D2196F3);

  // Overlays and shadows
  static const barrier = Color(0x80000000);
  static const shadowCard = Color(0x1F000000); // black12
  static const shadowRaised = Color(0x42000000); // black26
  static const shadowHeader = Color(0x78000000); // black, alpha 120

  // Map heatmap gradient
  static const heatmapLow = Colors.green;
  static const heatmapMid = Colors.yellow;
  static const heatmapHigh = Colors.red;
}

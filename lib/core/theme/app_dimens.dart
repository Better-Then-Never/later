import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Corner radii used by the design (DESIGN_SPEC.md §4).
abstract final class AppRadii {
  static const double xl = 30;
  static const double l = 25;
  static const double m = 20;
  static const double thumbnail = 17;
  static const double header = 16;
  static const double card15 = 15;
  static const double s = 12;
  static const double xs = 10;
  static const double xxs = 8;
  static const double checkbox = 5;

  static const lCircular = BorderRadius.all(Radius.circular(l));
}

/// Spacing scale (DESIGN_SPEC.md §6). Odd one-off values stay inline.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 20;
  static const double xxl = 24;
}

/// Shadows (DESIGN_SPEC.md §5).
abstract final class AppShadows {
  static const card = [
    BoxShadow(
      color: AppColors.shadowCard,
      blurRadius: 9,
      spreadRadius: 1,
      offset: Offset(0, 4),
    ),
  ];

  static const softCard = [
    BoxShadow(
      color: AppColors.shadowCard,
      blurRadius: 16,
      spreadRadius: 1,
      offset: Offset(0, 6),
    ),
  ];

  static const raised = [
    BoxShadow(
      color: AppColors.shadowRaised,
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const mapInfo = [
    BoxShadow(color: AppColors.shadowRaised, blurRadius: 8),
  ];

  static const header = [
    BoxShadow(
      color: AppColors.shadowHeader,
      blurRadius: 20,
      spreadRadius: 15,
      offset: Offset(0, 6),
    ),
  ];
}

/// How long toasts stay on screen. Animation timings live in AppMotion.
abstract final class AppDurations {
  static const toastShort = Duration(seconds: 2);
  static const toastLong = Duration(seconds: 3);
}

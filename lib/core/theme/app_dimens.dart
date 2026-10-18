import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_palette.dart';

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

/// Shadows (DESIGN_SPEC.md §5), in the colour of the current theme (dark mode
/// uses deeper shadows; cards there also get a hairline edge).
/// Fixed sizes of shared controls.
abstract final class AppSizes {
  /// The floating controls over the map (zoom, compass, my location, filter,
  /// streak): one scale, as small as a tap target may be (M-01).
  static const double mapControl = 44;

  /// Space between stacked map controls.
  static const double mapControlGap = 10;
}

abstract final class AppShadows {
  static List<BoxShadow> card(BuildContext context) => [
    BoxShadow(
      color: context.palette.shadowCard,
      blurRadius: 9,
      spreadRadius: 1,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> softCard(BuildContext context) => [
    BoxShadow(
      color: context.palette.shadowCard,
      blurRadius: 16,
      spreadRadius: 1,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> raised(BuildContext context) => [
    BoxShadow(
      color: context.palette.shadowRaised,
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> mapInfo(BuildContext context) => [
    BoxShadow(color: context.palette.shadowRaised, blurRadius: 8),
  ];

  /// Over the profile photo: the same in both themes.
  static const header = [
    BoxShadow(
      color: AppColors.mediaShade,
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

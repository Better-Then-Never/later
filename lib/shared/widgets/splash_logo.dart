import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';
import '../../core/theme/app_colors.dart';

/// The first Flutter frame: the map's ground with the Later logo, drawn
/// exactly like the native launch screen (android/.../launch_background.xml:
/// 132 dp wide, centred, values/colors.xml), so start-up has no flash or
/// jump; the map's cover is the same colour (docs/map/COLD_START.md).
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  static const width = 132.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.mapGroundDark
          : AppColors.mapGroundLight,
      child: Center(
        child: Image.asset(
          AppImages.laterLogo,
          width: width,
          // Decoded at the size it is drawn.
          cacheWidth: (width * MediaQuery.devicePixelRatioOf(context)).round(),
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

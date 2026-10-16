import 'package:flutter/material.dart';

import '../../core/assets/app_assets.dart';
import '../../core/theme/app_palette.dart';

/// The first Flutter frame: the page background with the Later logo, drawn
/// exactly like the native launch screen (android/.../launch_background.xml:
/// 132 dp wide, centred), so start-up has no flash or jump.
class SplashLogo extends StatelessWidget {
  const SplashLogo({super.key});

  static const width = 132.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.background,
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

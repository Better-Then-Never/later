import 'package:flutter/material.dart';

import '../../app/router/app_routes.dart';
import '../../core/assets/app_assets.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import 'package:later/core/theme/app_text_styles.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, -48.0),
                  child: Column(
                    children: [
                      Image.asset(AppImages.laterLogo, height: 300, width: 200),
                      Transform.translate(
                        offset: const Offset(0, -32.0),
                        child: Column(
                          children: [
                            // Longer translations shrink to stay on one line.
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                l10n.authWelcomeTo,
                                style: const TextStyle(
                                  fontSize: 40.0,
                                  fontFamily: kAppFontFamily,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Transform.translate(
                              offset: const Offset(0, -18.0),
                              child: Text(
                                l10n.appName,
                                style: const TextStyle(
                                  fontSize: 40.0,
                                  fontFamily: kAppFontFamily,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Transform.translate(
                              offset: const Offset(0, -24.0),
                              child: Text(
                                l10n.authWelcomeSubtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: kAppFontFamily,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        width: 325,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => AppRoutes.toLogin(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                          ),
                          child: Transform.translate(
                            offset: const Offset(0, -2.0),
                            child: Text(
                              l10n.authGetStarted,
                              style: const TextStyle(
                                fontFamily: kAppFontFamily,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onAccent,
                                fontSize: 28.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

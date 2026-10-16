import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';

/// Logo + "Log In Now"/"Sign Up Now" heading + subtitle.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(AppImages.laterLogo, height: 150, width: 120),
        Column(
          children: [
            Text(
              title,
              style: AppTextStyles.authHeading,
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.authSubheading,
            ),
          ],
        ),
      ],
    );
  }
}

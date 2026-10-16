import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import 'package:later/core/theme/app_colors.dart';

/// "Or connect with" + Google | Facebook icons.
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key, required this.onGoogle});

  final VoidCallback? onGoogle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Or connect with'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Continue with Google',
              onPressed: onGoogle,
              icon: Image.asset(AppIcons.authGoogle, height: 40.0, width: 40.0),
            ),
            const SizedBox(
              height: 40,
              child: VerticalDivider(
                color: AppColors.black,
                width: 20,
                thickness: 2,
              ),
            ),
            IconButton(
              tooltip: 'Facebook (coming soon)',
              // Facebook login is not implemented (see IDEAS_NOT_DONE.md).
              onPressed: () {},
              icon: Image.asset(
                AppIcons.authFacebook,
                height: 40.0,
                width: 40.0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

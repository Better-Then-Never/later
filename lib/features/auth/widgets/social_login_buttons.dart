import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';

/// "Or connect with" + Google | Facebook icons.
class SocialLoginButtons extends StatelessWidget {
  const SocialLoginButtons({super.key, required this.onGoogle});

  final VoidCallback? onGoogle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.authOrConnectWith),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: l10n.authContinueWithGoogle,
              onPressed: onGoogle,
              icon: Image.asset(AppIcons.authGoogle, height: 40.0, width: 40.0),
            ),
            SizedBox(
              height: 40,
              child: VerticalDivider(
                // The same ink as the auth fields' outlines.
                color: context.palette.textPrimary,
                width: 20,
                thickness: 2,
              ),
            ),
            IconButton(
              tooltip: l10n.authFacebookSoon,
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

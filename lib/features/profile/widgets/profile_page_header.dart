import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:later/features/profile/widgets/profile_background_picture.dart';
import 'package:later/features/profile/widgets/profile_picture.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/features/profile/widgets/profile_page_header_action_buttons.dart';
import 'package:later/shared/widgets/user/user_name_and_username.dart';
import 'package:later/core/theme/app_colors.dart';

class ProfilePageHeader extends StatelessWidget {
  final double screenWidth;
  final String userId;

  const ProfilePageHeader({
    super.key,
    required this.screenWidth,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const ProfileBackgroundPicture(pictureHeight: 230),
        Container(
          width: screenWidth,
          height: 1,
          decoration: BoxDecorations.blackShadow(),
        ),
        Positioned(
          // Below the status bar / notch on every device (BUG-086); 35 on
          // phones with a regular status bar, as before.
          top: math.max(35, MediaQuery.paddingOf(context).top + 8),
          right: 12,
          child: const ProfilePageHeaderActionButtons(),
        ),
        Positioned(
          top: 99,
          left: 16,
          child: SizedBox(
            width: screenWidth - 32,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const ProfilePicture(pictureHeight: 115, pictureWidth: 115),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: UserNameAndUsername(
                    userId: userId,
                    nameFontSize: 32,
                    usernameFontSize: 20,
                    nameColor: AppColors.onMedia,
                    usernameColor: AppColors.onMedia,
                    nameFontWeight: FontWeight.bold,
                    usernameFontWeight: FontWeight.bold,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

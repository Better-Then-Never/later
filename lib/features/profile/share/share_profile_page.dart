import 'package:flutter/material.dart';
import 'package:later/features/profile/share/sharing_service.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/shared/styles/elevated_button_styles.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/buttons/go_back_button.dart';
import 'package:later/features/profile/share/share_profile_qr.dart';
import 'package:later/shared/widgets/user/user_name_and_username.dart';
import 'package:provider/provider.dart';
import 'package:later/shared/widgets/page_header.dart';
import 'package:later/core/theme/app_colors.dart';

class ShareProfilePage extends StatelessWidget {
  const ShareProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Always the real uid: the QR code and link were built from 'No User'
    // until the profile had loaded (BUG-092).
    final userId = context.read<SessionController>().uid!;
    final profileLink = SharingService.generateProfileLink(userId);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          PageHeader(
            mainText: 'Share Profile',
            leadingButton: GoBackButton(context: context),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.005),
                DefaultText(
                  'Share Your Profile',
                  fontSize: screenWidth * 0.065,
                  fontWeight: FontWeight.bold,
                ),
                DefaultText(
                  'Let others scan this QR code to add you as a friend',
                  fontSize: screenWidth * 0.042,
                  color: AppColors.grey600,
                ),
                SizedBox(height: screenHeight * 0.03),
                ShareProfileQR(
                  profileLink: profileLink,
                  screenWidth: screenWidth,
                ),
                SizedBox(height: screenHeight * 0.02),

                UserNameAndUsername(
                  userId: userId,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),

                SizedBox(height: screenHeight * 0.03),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: screenHeight * 0.06,
                        child: ElevatedButton.icon(
                          style: ElevatedButtonStyles.roundedButtonStyle(
                            borderRadius: 15,
                            foregroundColor: AppColors.white,
                            color: AppColors.brandGreen,
                          ),
                          onPressed: () => SharingService.shareUserProfile(
                            context: context,
                            userId: userId,
                          ),
                          icon: const Icon(Icons.share, size: 20),
                          label: DefaultText(
                            'Share',
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: SizedBox(
                        height: screenHeight * 0.06,
                        child: ElevatedButton.icon(
                          style: ElevatedButtonStyles.roundedButtonStyle(
                            borderRadius: 15,
                            color: AppColors.grey300,
                            foregroundColor: AppColors.black,
                          ),
                          onPressed: () => SharingService.copyProfileLink(
                            context: context,
                            userId: userId,
                          ),
                          icon: const Icon(Icons.copy, size: 20),
                          label: DefaultText(
                            'Copy Link',
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecorations.lightBlueInfo(),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.infoBlue600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DefaultText(
                          'Others can scan this code with their camera or the app to add you as a friend',
                          fontSize: screenWidth * 0.037,
                          color: AppColors.infoBlue700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

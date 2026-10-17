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
import 'package:later/core/theme/app_palette.dart';
import 'package:later/core/l10n/l10n.dart';

class ShareProfilePage extends StatelessWidget {
  const ShareProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final palette = context.palette;
    final l10n = context.l10n;
    // Always the real uid: the QR code and link were built from 'No User'
    // until the profile had loaded (BUG-092).
    final userId = context.read<SessionController>().uid!;
    final profileLink = SharingService.generateProfileLink(userId);

    return Scaffold(
      backgroundColor: palette.background,
      body: Column(
        children: [
          PageHeader(
            mainText: l10n.profileShareTitle,
            leadingButton: GoBackButton(context: context),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                SizedBox(height: screenHeight * 0.005),
                DefaultText(
                  l10n.profileShareHeading,
                  fontSize: screenWidth * 0.065,
                  fontWeight: FontWeight.bold,
                ),
                DefaultText(
                  l10n.profileShareSubtitle,
                  fontSize: screenWidth * 0.042,
                  color: palette.textMuted,
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
                            foregroundColor: AppColors.onAccent,
                            color: AppColors.brandGreen,
                          ),
                          onPressed: () => SharingService.shareUserProfile(
                            context: context,
                            userId: userId,
                          ),
                          icon: const Icon(Icons.share, size: 20),
                          // Longer translations shrink instead of wrapping.
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: DefaultText(
                              l10n.profileShare,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onAccent,
                            ),
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
                            color: palette.skeleton,
                            foregroundColor: palette.icon,
                          ),
                          onPressed: () => SharingService.copyProfileLink(
                            context: context,
                            userId: userId,
                          ),
                          icon: const Icon(Icons.copy, size: 20),
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: DefaultText(
                              l10n.profileCopyLink,
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.03),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecorations.lightBlueInfo(context),
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
                          l10n.profileShareHint,
                          fontSize: screenWidth * 0.037,
                          // Blue 700 is too dark to read on the dark card.
                          color: palette.isDark
                              ? AppColors.infoBlue
                              : AppColors.infoBlue700,
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

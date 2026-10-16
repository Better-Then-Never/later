import 'package:flutter/material.dart';
import 'package:later/app/router/app_routes.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/features/profile/share/sharing_service.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/shared/widgets/buttons/default_button_with_icon.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/shadow_top_overlay.dart';
import 'package:later/features/friends/widgets/profile/friend_profile_action_buttons_row.dart';
import 'package:later/features/profile/widgets/profile_header_background_image.dart';
import 'package:later/shared/widgets/user/user_name_and_username.dart';
import 'package:later/shared/widgets/user/user_square_avatar.dart';
import 'package:later/features/friends/widgets/friend_options_modal.dart';
import 'package:later/core/theme/app_colors.dart';

class YourFriendProfilePage extends StatelessWidget {
  final String friendUid;

  const YourFriendProfilePage({super.key, required this.friendUid});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                ProfileHeaderBackground(userId: friendUid),
                ShadowTopOverlay(width: screenWidth),
                ProfileActionButtonsRow(
                  onBack: () => Navigator.pop(context),
                  onShare: () => SharingService.shareUserProfile(
                    context: context,
                    userId: friendUid,
                  ),
                  onOptions: () => FriendOptionsModal.show(context, friendUid),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    left: screenWidth * 0.04,
                    top: screenHeight * 0.108,
                  ),
                  child: SizedBox(
                    width: screenWidth - 32,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        UserSquareAvatar(
                          userId: friendUid,
                          size: 115,
                          borderRadius: 25,
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        Expanded(
                          child: UserNameAndUsername(
                            userId: friendUid,
                            nameFontSize: screenWidth * 0.07,
                            usernameFontSize: screenWidth * 0.05,
                            nameColor: AppColors.white,
                            usernameColor: AppColors.white,
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DefaultButtonWithIcon(
                          decoration: BoxDecorations.whiteCard(context),
                          textFontSize: 18,
                          textFontWeight: FontWeight.bold,
                          onTap: () => AppRoutes.toChat(context, friendUid),
                          assetPath: AppIcons.sendMessage,
                          text: 'Open chat',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DefaultButtonWithIcon(
                          decoration: BoxDecorations.whiteCard(context),
                          textFontSize: 18,
                          textFontWeight: FontWeight.bold,
                          onTap: () => AppRoutes.toCamera(
                            context,
                            privacy: CapsulePrivacy.private,
                            recipientId: friendUid,
                          ),
                          assetPath: AppIcons.sendCapsule,
                          text: 'Send Capsule',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const DefaultText(
                    "Friend's capsules",
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: screenWidth - 32,
                    height: 80,
                    decoration: BoxDecorations.whiteCard(context),
                    child: const Center(
                      child: DefaultText(
                        "Friend's capsules will appear here",
                        fontSize: 16,
                        color: AppColors.grey600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:later/services/sharing_service.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_buttons/default_button_with_icon.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/_common/default_elements/shadow_top_overlay.dart';
import 'package:later/views/widgets/add_friend_profile/friend_profile_action_buttons_row.dart';
import 'package:later/views/widgets/my_profile_page/profile_header_background_image.dart';
import 'package:later/views/widgets/user/user_name_and_username.dart';
import 'package:later/views/widgets/user/user_square_avatar.dart';
import 'package:later/views/widgets/friends/friend_options_modal.dart';

class YourFriendProfilePage extends StatelessWidget {
  final String friendUid;

  const YourFriendProfilePage({super.key, required this.friendUid});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
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
                    left: screenWidth * 0.05,
                    top: screenHeight * 0.13,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      UserSquareAvatar(
                        userId: friendUid,
                        size: 110,
                        borderRadius: 25,
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      UserNameAndUsername(
                        userId: friendUid,
                        nameFontSize: screenWidth * 0.07,
                        usernameFontSize: screenWidth * 0.05,
                        nameColor: Colors.white,
                        usernameColor: Colors.white,
                        textAlign: TextAlign.left,
                      ),
                    ],
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
                          decoration: BoxDecorations.whiteCard(),
                          textFontSize: 16,
                          textFontWeight: FontWeight.bold,
                          onTap: () {}, // TODO: Open chat with friend
                          assetPath:
                              'assets/images/icons/prof_page/send_message.png',
                          text: 'Open chat',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DefaultButtonWithIcon(
                          decoration: BoxDecorations.whiteCard(),
                          textFontSize: 16,
                          textFontWeight: FontWeight.bold,
                          onTap: () {}, // TODO: Send Capsule to friend
                          assetPath:
                              'assets/images/icons/prof_page/send_capsule.png',
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
                    decoration: BoxDecorations.whiteCard(),
                    child: Center(
                      child: DefaultText(
                        "Friend's capsules will appear here",
                        fontSize: 16,
                        color: Colors.grey[600],
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

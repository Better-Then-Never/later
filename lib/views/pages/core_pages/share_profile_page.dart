import 'package:flutter/material.dart';
import 'package:later/services/sharing_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/styles/elevated_button_styles.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/_common/premade_buttons/go_back_button.dart';
import 'package:later/views/widgets/share_profile/share_profile_qr.dart';
import 'package:later/views/widgets/user/user_name_and_username.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';

class ShareProfilePage extends StatelessWidget {
  const ShareProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final userService = Provider.of<UserDataService>(context);
    final userId = userService.currentLoggedInUid;
    final profileLink = SharingService.generateProfileLink(userId);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
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
                  color: Colors.grey[600],
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
                      child: Container(
                        height: screenHeight * 0.06,
                        child: ElevatedButton.icon(
                          style: ElevatedButtonStyles.roundedButtonStyle(
                            borderRadius: 15,
                            foregroundColor: Colors.white,
                            color: const Color.fromARGB(255, 86, 201, 46),
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
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 16),

                    Expanded(
                      child: Container(
                        height: screenHeight * 0.06,
                        child: ElevatedButton.icon(
                          style: ElevatedButtonStyles.roundedButtonStyle(
                            borderRadius: 15,
                            color: const Color.fromARGB(255, 226, 226, 226),
                            foregroundColor: Colors.black,
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
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecorations.lightBlueInfo(),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: DefaultText(
                          'Others can scan this code with their camera or the app to add you as a friend',
                          fontSize: screenWidth * 0.037,
                          color: Colors.blue[700],
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

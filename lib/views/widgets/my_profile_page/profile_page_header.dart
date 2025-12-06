import 'package:flutter/material.dart';
import 'package:later/views/widgets/my_profile_page/profile_background_picture.dart';
import 'package:later/views/widgets/my_profile_page/profile_picture.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/widgets/my_profile_page/profile_page_header_action_buttons.dart';
import 'package:later/views/widgets/user/user_name_and_username.dart';

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
    Provider.of<UserDataService>(context);

    return Stack(
      children: [
        ProfileBackgroundPicture(
          allignment: Alignment.topLeft,
          pictureHeight: 230,
          pictureWidth: screenWidth,
        ),
        Container(
          width: screenWidth,
          height: 1,
          decoration: BoxDecorations.blackShadow(),
        ),
        Positioned(
          top: 35,
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
                    nameColor: Colors.white,
                    usernameColor: Colors.white,
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

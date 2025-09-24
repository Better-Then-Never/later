import 'package:flutter/material.dart';
import 'package:later/services/profile_friends/background_picture.dart';
import 'package:later/services/profile_friends/prof_picture.dart';
import 'package:later/views/widgets/common/decorations/box_decorations.dart';
import 'package:later/views/widgets/common/default_text.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_profile_data_service.dart';
import 'package:later/views/widgets/profile_page/profile_page_header_action_buttons.dart';

class ProfilePageHeader extends StatelessWidget {
  final double screenWidth;

  const ProfilePageHeader({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    final userProfileService = Provider.of<UserProfileService>(context);

    return Stack(
      children: [
        BackgroundPicture(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const ProfilePicture(pictureHeight: 115, pictureWidth: 115),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DefaultText(
                    userProfileService.name,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  DefaultText(
                    '@' + userProfileService.username,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

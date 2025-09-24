import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart ';

class ProfilePageHeaderActionButtons extends StatelessWidget {
  const ProfilePageHeaderActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DefaultIconButton(
          size: 45,
          assetPath: 'assets/images/icons/prof_page/notifications_button.png',
          onTap: () {
            Navigator.pushNamed(context, '/notificationsPage');
          },
        ),
        DefaultIconButton(
          size: 41,
          assetPath: 'assets/images/icons/prof_page/share_button.png',
          onTap: () {
            Navigator.pushNamed(context, '/sharePage');
          },
        ),
        DefaultIconButton(
          size: 41,
          assetPath: 'assets/images/icons/prof_page/settings_button.png',
          onTap: () {
            Navigator.pushNamed(context, '/settingsPage');
          },
        ),
      ],
    );
  }
}

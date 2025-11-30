import 'package:flutter/material.dart';
import 'package:later/views/pages/core_pages/notifications_page.dart';
import 'package:later/views/pages/core_pages/settings_page.dart';
import 'package:later/views/pages/core_pages/share_profile_page.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';
import 'package:page_transition/page_transition.dart';

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
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.fade,
                duration: const Duration(milliseconds: 10),
                reverseDuration: const Duration(milliseconds: 10),
                child: NotificationsPage(),
              ),
            );
          },
        ),
        DefaultIconButton(
          size: 41,
          assetPath: 'assets/images/icons/prof_page/share_button.png',
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.fade,
                duration: const Duration(milliseconds: 10),
                reverseDuration: const Duration(milliseconds: 10),
                child: ShareProfilePage(),
              ),
            );
          },
        ),
        DefaultIconButton(
          size: 41,
          assetPath: 'assets/images/icons/prof_page/settings_button.png',
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.fade,
                duration: const Duration(milliseconds: 10),
                reverseDuration: const Duration(milliseconds: 10),
                child: SettingsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
}

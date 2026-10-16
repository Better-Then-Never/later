import 'package:flutter/material.dart';

import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/options/options_settings_row.dart';
import '../../profile/widgets/profile_background_picture.dart';
import '../../profile/widgets/profile_picture.dart';
import '../widgets/settings_scaffold.dart';
import 'name_settings_page.dart';
import 'username_settings_page.dart';

/// Pictures, name and username in one place. Tap a picture to change or
/// delete it, as on the profile page.
class ProfileCustomizationSettingsPage extends StatelessWidget {
  const ProfileCustomizationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final backgroundHeight = screenWidth * 0.45;
    final pictureSize = screenWidth * 0.3;
    return SettingsScaffold(
      title: 'Customize profile',
      description: 'Tap a picture to change it',
      children: [
        Center(
          child: SizedBox(
            width: screenWidth * 0.92,
            height: backgroundHeight + pictureSize / 2,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: ProfileBackgroundPicture(
                    pictureHeight: backgroundHeight,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: ProfilePicture(
                    pictureHeight: pictureSize,
                    pictureWidth: pictureSize,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: screenWidth * 0.05),
        const OptionsSection(
          children: [
            OptionsSettingsRow(title: 'Name', navigateTo: NameSettingsPage()),
            OptionsSettingsRow(
              title: 'Username',
              withDivider: false,
              navigateTo: UsernameSettingsPage(),
            ),
          ],
        ),
      ],
    );
  }
}

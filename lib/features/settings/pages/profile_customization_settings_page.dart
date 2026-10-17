import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
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
    final l10n = context.l10n;
    return SettingsScaffold(
      title: l10n.settingsCustomizeProfile,
      description: l10n.settingsCustomizeDescription,
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
        OptionsSection(
          children: [
            OptionsSettingsRow(
              title: l10n.settingsName,
              navigateTo: const NameSettingsPage(),
            ),
            OptionsSettingsRow(
              title: l10n.settingsUsername,
              withDivider: false,
              navigateTo: const UsernameSettingsPage(),
            ),
          ],
        ),
      ],
    );
  }
}

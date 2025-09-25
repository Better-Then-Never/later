import 'package:flutter/material.dart';
import 'package:later/views/pages/options_settings_pages/name_changing_page.dart';
import 'package:later/services/firebase_auth_service.dart';
import 'package:later/views/pages/options_settings_pages/password_changing_page.dart';
import 'package:later/views/pages/options_settings_pages/language_settings_page.dart';
import 'package:later/views/pages/options_settings_pages/profile_customization_settings_page.dart';
import 'package:later/views/pages/options_settings_pages/app_theme_settings_page.dart';
import 'package:later/views/pages/options_settings_pages/permissions_settings_page.dart';
import 'package:later/views/pages/options_settings_pages/username_settings_page.dart';
import 'package:later/views/widgets/_common/default_elements/confirm_dialog.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/_common/options_elements/options_settings_row.dart';
import 'package:later/views/widgets/_common/premade_buttons/go_back_button.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/services/image_assets_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileService = context.watch<UserDataService>();
    final assetService = AssetImageService();

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          PageHeader(
            mainText: 'Settings',
            leadingButton: GoBackButton(context: context),
          ),
          SafeArea(
            child: Column(
              children: [
                Row(
                  children: [
                    DefaultText(
                      "MY ACCOUNT",
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.09,
                        bottom: screenHeight * 0.01,
                      ),
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                    ),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      width: screenWidth * 0.92,
                      decoration: BoxDecorations.whiteCard(),
                      child: Column(
                        children: [
                          OptionsSettingsRow(
                            title: 'Name',
                            subtitle: DefaultText(
                              userProfileService.name,
                              textAlign: TextAlign.left,
                            ),
                            navigateTo: NameSettingsPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Username',
                            subtitle: DefaultText(
                              '@' + userProfileService.username,
                              textAlign: TextAlign.left,
                            ),
                            navigateTo: UsernameSettingsPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Email',
                            subtitle: DefaultText(
                              userProfileService.email,
                              textAlign: TextAlign.left,
                            ),
                            navigateTo: NameSettingsPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Password',
                            navigateTo: PasswordSettingsPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Language',
                            navigateTo: LanguageSettingsPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'App apperance',
                            navigateTo: AppThemeSettingsPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Customize profile',
                            navigateTo: ProfileCustomizationSettingsPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'App permissions',
                            navigateTo: PermissionsSettingsPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Log Out',
                            isLast: true,
                            onTap: () {
                              ConfirmDialog.show(
                                context: context,
                                title: 'Sosal?',
                                onConfirm: () async {
                                  FirebaseAuthService().signOut();
                                  Navigator.of(context).pop();
                                  await assetService.clearLocalCache();
                                  if (!context.mounted) return;
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/loginPage',
                                    (route) => false,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

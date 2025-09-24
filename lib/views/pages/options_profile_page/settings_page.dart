import 'package:flutter/material.dart';
import 'package:later/services/profile_friends/background_picture.dart';
import 'package:later/services/profile_friends/prof_picture.dart';
import 'package:later/views/pages/options_settings_page/name_changing.dart';
import 'package:later/services/auth/auth_services.dart';
import 'package:later/views/pages/options_settings_page/password_changing.dart';
import 'package:later/views/pages/options_settings_page/language.dart';
import 'package:later/views/pages/options_settings_page/profile_custom.dart';
import 'package:later/views/pages/options_settings_page/app_theme.dart';
import 'package:later/views/pages/options_settings_page/permissions_settings.dart';
import 'package:later/views/pages/options_settings_page/username_changing.dart';
import 'package:later/views/widgets/common/confirm_dialog.dart';
import 'package:later/views/widgets/common/default_text.dart';
import 'package:later/views/widgets/common/options_elements/options_settings_row.dart';
import 'package:later/views/widgets/common/premade_buttons/go_back_button.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/common/page_header.dart';
import 'package:later/services/user_profile_data_service.dart';
import 'package:later/views/widgets/common/decorations/box_decorations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userProfileService = context.watch<UserProfileService>();

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
                            navigateTo: NameChangingPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Username',
                            subtitle: DefaultText(
                              '@' + userProfileService.username,
                              textAlign: TextAlign.left,
                            ),
                            navigateTo: UsernameChangingPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Email',
                            subtitle: DefaultText(
                              userProfileService.email,
                              textAlign: TextAlign.left,
                            ),
                            navigateTo: NameChangingPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Password',
                            navigateTo: PasswordChangingPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Language',
                            navigateTo: LanguageChangingPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'App apperance',
                            navigateTo: AppThemePage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Customize profile',
                            navigateTo: ProfileCustomizationPage(),
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
                                  AuthService().signOut();
                                  Navigator.of(context).pop();
                                  await clearProfileImageCache();
                                  await clearBackgroundImageCache();
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

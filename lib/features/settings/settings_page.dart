import 'package:flutter/material.dart';
import 'package:later/features/settings/pages/email_settings_page.dart';
import 'package:later/features/settings/pages/name_settings_page.dart';
import 'package:later/features/settings/pages/password_settings_page.dart';
import 'package:later/features/settings/pages/language_settings_page.dart';
import 'package:later/features/settings/pages/profile_customization_settings_page.dart';
import 'package:later/features/settings/pages/app_theme_settings_page.dart';
import 'package:later/features/settings/pages/permissions_settings_page.dart';
import 'package:later/features/settings/pages/username_settings_page.dart';
import 'package:later/shared/widgets/confirm_dialog.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/options/options_settings_row.dart';
import 'package:later/shared/widgets/buttons/go_back_button.dart';
import 'package:provider/provider.dart';
import 'package:later/shared/widgets/page_header.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/shared/styles/box_decorations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final profile = session.profile;

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
                      'MY ACCOUNT',
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
                              profile?.name ?? 'Loading...',
                              textAlign: TextAlign.left,
                            ),
                            navigateTo: const NameSettingsPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Username',
                            subtitle: DefaultText(
                              '@${profile?.username ?? 'Loading...'}',
                              textAlign: TextAlign.left,
                            ),
                            navigateTo: const UsernameSettingsPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Email',
                            subtitle: DefaultText(
                              // From Auth: the copy in users/{uid} is to be
                              // removed (MIGRATIONS_NEEDED.md).
                              session.email ?? 'Loading...',
                              textAlign: TextAlign.left,
                            ),
                            navigateTo: const EmailSettingsPage(),
                          ),

                          const OptionsSettingsRow(
                            title: 'Password',
                            navigateTo: PasswordSettingsPage(),
                          ),

                          const OptionsSettingsRow(
                            title: 'Language',
                            navigateTo: LanguageSettingsPage(),
                          ),

                          const OptionsSettingsRow(
                            title: 'App appearance',
                            navigateTo: AppThemeSettingsPage(),
                          ),

                          const OptionsSettingsRow(
                            title: 'Customize profile',
                            navigateTo: ProfileCustomizationSettingsPage(),
                          ),

                          const OptionsSettingsRow(
                            title: 'App permissions',
                            navigateTo: PermissionsSettingsPage(),
                          ),

                          OptionsSettingsRow(
                            title: 'Log Out',
                            isLast: true,
                            onTap: () {
                              ConfirmDialog.show(
                                context: context,
                                title: 'Are you sure you want to log out?',
                                // The session resets every per-user store and
                                // the auth gate shows the login page.
                                onConfirm: () =>
                                    context.read<SessionController>().signOut(),
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

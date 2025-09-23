import 'package:flutter/material.dart';
import 'package:later/services/profile_friends/background_picture.dart';
import 'package:later/services/profile_friends/prof_picture.dart';
import 'package:later/views/pages/options_settings_page/email_changing.dart';
import 'package:later/views/pages/options_settings_page/name_changing.dart';
import 'package:later/services/profile_friends/name_getting.dart';
import 'package:later/services/auth/auth_services.dart';
import 'package:later/services/profile_friends/username_getting.dart';
import 'package:later/views/pages/options_settings_page/username_changing.dart';
import 'package:later/services/profile_friends/email_getting.dart';
import 'package:later/views/pages/options_settings_page/password_changing.dart';
import 'package:later/views/pages/options_settings_page/language.dart';
import 'package:later/views/pages/options_settings_page/profile_custom.dart';
import 'package:later/views/pages/options_settings_page/app_theme.dart';
import 'package:later/services/cache_firebase/user_services.dart';
import 'package:later/views/pages/options_settings_page/permissions_settings.dart';
import 'package:later/views/widgets/common/confirm_dialog.dart';
import 'package:later/views/widgets/common/default_text.dart';
import 'package:later/views/widgets/common/options_elements/options_settings_row.dart';
import 'package:later/views/widgets/common/premade_buttons/go_back_button.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/common/page_header.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context, listen: false);
    final String uid = userService.uid ?? 'null';
    
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(
              mainText: 'Settings',
              leadingButton: GoBackButton(context: context),
            ),
            SizedBox(height: screenHeight * 0.015),
            Row(
              children: [
                DefaultText(
                  "MY ACCOUNT",
                  padding: EdgeInsets.only(left: screenWidth * 0.09),
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.045,
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.005),
            Column(
              children: [
                Container(
                  width: screenWidth * 0.92,
                  height: screenHeight * 0.52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        spreadRadius: 1,
                        blurRadius: 9,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      OptionsSettingsRow(
                        title: 'Name',
                        subtitle: NameGettingWidget(
                          uid: uid,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontFamily: 'Irina',
                            color: Color.fromARGB(255, 94, 94, 94),
                          ),
                        ),
                        navigateTo: NameChangingPage(),
                      ),

                      OptionsSettingsRow(
                        title: 'Username',
                        subtitle: UsernameGettingWidget(
                          uid: uid,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontFamily: 'Irina',
                            color: Color.fromARGB(255, 94, 94, 94),
                          ),
                        ),
                        navigateTo: UsernameChangingPage(),
                      ),

                      OptionsSettingsRow(
                        title: 'Email',
                        subtitle: EmailGettingWidget(
                          uid: uid,
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontFamily: 'Irina',
                            color: Color.fromARGB(255, 94, 94, 94),
                          ),
                        ),
                        navigateTo: EmailChangingPage(),
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
            SizedBox(height: screenHeight * 0.03),
          ],
        ),
      ),
    );
  }
}

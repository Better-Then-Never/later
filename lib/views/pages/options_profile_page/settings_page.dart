import 'package:flutter/material.dart';
import 'package:later/views/pages/options_settings_page/email_changing.dart';
import 'package:later/views/pages/options_settings_page/name_changing.dart';
import 'package:later/views/widgets/name_getting.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:later/views/widgets/prof_picture.dart';
import 'package:later/views/widgets/background_picture.dart';
import 'package:later/views/widgets/username_getting.dart';
import 'package:later/views/pages/options_settings_page/username_changing.dart';
import 'package:later/views/widgets/email_getting.dart';
import 'package:later/views/pages/options_settings_page/password_changing.dart';
import 'package:later/views/pages/options_settings_page/language.dart';
import 'package:later/views/pages/options_settings_page/profile_custom.dart';
import 'package:later/views/pages/options_settings_page/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? 'null';
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: screenWidth,
              height: screenHeight * 0.12,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 5,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: screenWidth * 0.10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Irina',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Image.asset(
                        'assets/images/icons/prof_page/go_back.png',
                        width: screenWidth * 0.11,
                        height: screenWidth * 0.11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.09),
              child: Text(
                'MY ACCOUNT',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.005),
            Center(
              child: Container(
                width: screenWidth * 0.92,
                height: screenHeight * 0.47,
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
                    _settingsRow(
                      context,
                      'Name',
                      null,
                      customSubtitle: NameGettingWidget(
                        uid: uid,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontFamily: 'Irina',
                          color: Color.fromARGB(255, 94, 94, 94),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NameChangingWidget(),
                          ),
                        );
                      },
                      screenWidth: screenWidth,
                    ),
                    _settingsRow(
                      context,
                      'Username',
                      null,
                      customSubtitle: UsernameGettingWidget(
                        uid: uid,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontFamily: 'Irina',
                          color: Color.fromARGB(255, 94, 94, 94),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const UsernameChangingWidget(),
                          ),
                        );
                      },
                      screenWidth: screenWidth,
                    ),
                    _settingsRow(
                      context,
                      'Email',
                      null,
                      customSubtitle: EmailGettingWidget(
                        uid: uid,
                        style: TextStyle(
                          fontSize: screenWidth * 0.045,
                          fontFamily: 'Irina',
                          color: Color.fromARGB(255, 94, 94, 94),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmailChangingWidget(),
                          ),
                        );
                      },
                      screenWidth: screenWidth,
                    ),
                    _settingsRow(
                      context,
                      'Password',
                      null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PasswordChangingPage(),
                          ),
                        );
                      },
                      screenWidth: screenWidth,
                    ),
                    _settingsRow(
                      context,
                      'Language',
                      null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LanguagePage(),
                          ),
                        );
                      },
                      screenWidth: screenWidth,
                    ),
                    _settingsRow(
                      context,
                      'App Appearance',
                      null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppThemePage(),
                          ),
                        );
                      },
                      screenWidth: screenWidth,
                    ),
                    _settingsRow(
                      context,
                      'Customize Profile',
                      null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ProfileCustomizationPage(),
                          ),
                        );
                      },
                      screenWidth: screenWidth,
                    ),
                    _settingsRow(
                      context,
                      'Log Out',
                      null,
                      isLogout: true,
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          isScrollControlled: true,
                          barrierColor: Colors.black.withAlpha(128),
                          builder: (BuildContext context) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                Navigator.of(context).pop();
                              },
                              child: Center(
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    width: 264,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 0,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            'Are you sure you want to log out?',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          width: 160,
                                          height: 40,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color.fromARGB(
                                                255,
                                                253,
                                                65,
                                                64,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                              ),
                                              elevation: 0,
                                              padding: EdgeInsets.zero,
                                            ),
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              await clearProfileImageCache();
                                              await clearBackgroundImageCache();
                                              if (!context.mounted) return;
                                              Navigator.pushNamedAndRemoveUntil(
                                                context,
                                                '/welcome',
                                                (route) => false,
                                              );
                                            },
                                            child: const Text(
                                              'Log Out',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 0),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Color.fromARGB(
                                              255,
                                              95,
                                              95,
                                              95,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      screenWidth: screenWidth,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
          ],
        ),
      ),
    );
  }
}

Widget _settingsRow(
  BuildContext context,
  String title,
  String? subtitle, {
  bool isLogout = false,
  VoidCallback? onTap,
  Widget? customSubtitle,
  required double screenWidth,
}) {
  return Column(
    children: [
      Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: ListTile(
          dense: true,
          minVerticalPadding: 6,
          visualDensity: VisualDensity(vertical: -3),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
              fontFamily: 'Irina',
              color: isLogout ? Color.fromARGB(255, 253, 65, 64) : Colors.black,
            ),
          ),
          subtitle:
              customSubtitle ??
              (subtitle != null
                  ? Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontFamily: 'Irina',
                        color: Color.fromARGB(255, 94, 94, 94),
                      ),
                    )
                  : null),
          trailing: isLogout
              ? null
              : Opacity(
                  opacity: 0.65,
                  child: Image.asset(
                    'assets/images/icons/prof_page/go_here.png',
                    width: screenWidth * 0.09,
                    height: screenWidth * 0.09,
                  ),
                ),
          contentPadding: EdgeInsets.only(
            left: screenWidth * 0.05,
            right: screenWidth * 0.03,
          ),
          onTap: onTap,
        ),
      ),
      if (!isLogout)
        const Divider(
          height: 1,
          thickness: 1,
          indent: 0,
          endIndent: 0,
          color: Color.fromARGB(255, 211, 211, 211),
        ),
    ],
  );
}

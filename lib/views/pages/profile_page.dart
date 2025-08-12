import 'package:flutter/material.dart';
import 'package:later/views/widgets/background_picture.dart';
import 'package:later/views/widgets/login_signup_pages/logout_button.dart';
import 'package:later/views/widgets/prof_picture.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          Stack(
            children: [
              BackgroundPicture(
                allignment: Alignment.topLeft,
                pictureHeight: 230,
                pictureWidth: MediaQuery.of(context).size.width,
              ),
              Positioned(
                top: 99,
                left: 16,
                child: ProfilePicture(
                  pictureHeight: 115,
                  pictureWidth: 115,
                ),
              ),
              Container(
                width: double.infinity,
                height: 1,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 0, 0),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(120),
                      spreadRadius: 60,
                      blurRadius: 20,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "My capsules",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 380,
            height: 80,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  spreadRadius: 1,
                  blurRadius: 9,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: SizedBox(
                      width: 40,
                      height: 40,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Image.asset(
                          'assets/images/icons/profile_page/my_capsules.png',
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 304,
                    height: 1,
                    color: Color.fromARGB(211, 211, 211, 211),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 160.0),
        child: LogOutButton(
          onSignedOut: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/welcome',
              (route) => false,
            );
          },
        ),
      ),
    );
  }
}

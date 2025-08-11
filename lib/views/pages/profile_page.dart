import 'package:flutter/material.dart';
import 'package:later/views/widgets/login_signup_pages/logout_button.dart';
import 'package:later/views/widgets/prof_picture.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Profile Page"),
            LogOutButton(
              onSignedOut: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                  (route) => false,
                );
              },
            ),
            SizedBox(height: 30),
            ProfilePicture( ),
          ],
        ),
      ),
    );
  }
}

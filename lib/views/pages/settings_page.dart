import 'package:flutter/material.dart';
import 'package:later/views/widgets/login_signup_pages/logout_button.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Center(
        child: Text(
          "Settings Page",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
        ),
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



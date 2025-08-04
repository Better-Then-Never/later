import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/later_logo.png",
                  height: 300,
                  width: 200,
                ),

                const Text(
                  'Welcome to',
                  style: TextStyle(fontSize: 32.0, color: Colors.black),
                  textAlign: TextAlign.center,
                ),

                Transform.translate(
                  offset: const Offset(0, -24.0),
                  child: const Text(
                    'Later',
                    style: TextStyle(
                      fontSize: 48.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),

                const Text(
                  'Create an account to get an access to\ncapsules of yours and your friends',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0, color: Colors.black87),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

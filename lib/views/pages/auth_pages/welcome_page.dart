import 'package:flutter/material.dart';
import 'package:later/views/pages/auth_pages/login_page.dart';

List<Widget> pages = [const LoginPage()];

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(0, -48.0),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/later_logo.png",
                        height: 300,
                        width: 200,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -32.0),
                        child: Column(
                          children: [
                            const Text(
                              'Welcome to',
                              style: TextStyle(
                                fontSize: 40.0,
                                fontFamily: 'Irina',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Transform.translate(
                              offset: const Offset(0, -18.0),
                              child: const Text(
                                'Later',
                                style: TextStyle(
                                  fontSize: 40.0,
                                  fontFamily: 'Irina',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Transform.translate(
                              offset: const Offset(0, -24.0),
                              child: const Text(
                                'Create an account to get an access to\ncapsules of yours and your friends',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16.0,
                                  fontFamily: 'Irina',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        width: 325,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/loginPage');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF56C92E),
                          ),
                          child: Transform.translate(
                            offset: const Offset(0, -2.0),
                            child: const Text(
                              'Get Started',
                              style: TextStyle(
                                fontFamily: 'Irina',
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 28.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

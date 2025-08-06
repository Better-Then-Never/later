import 'package:flutter/material.dart';
import 'package:later/views/widgets/registration_input_field.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(flex: 1, child: Container()), // Flexible spacing

                      Container(
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/images/later_logo.png",
                              height: 110,
                              width: 120,
                            ),
                            Column(
                              children: [
                                const Text(
                                  'Sign Up Now',
                                  style: TextStyle(
                                    fontSize: 40.0,
                                    fontFamily: 'Irina',
                                    letterSpacing: -1,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 0.0,
                                  ),
                                  child: Text(
                                    'Please fill the details to create your account',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontFamily: 'Irina',
                                      letterSpacing: 0.1,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            Column(
                              children: [
                                RegistrationInputField(textHint: "Name"),
                                const SizedBox(height: 10.0),
                                RegistrationInputField(textHint: "Nickname"),
                                const SizedBox(height: 10.0),
                                RegistrationInputField(textHint: "Email"),
                                const SizedBox(height: 10.0),
                                RegistrationInputField(
                                  textHint: "Password",
                                  isTextHidden: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 50),
                            SizedBox(
                              width: 275,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  // TODO: Email login
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/widgetTree',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF56C92E),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25.0),
                                  ),
                                ),
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    fontFamily: 'Irina',
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 32.0,
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Do you have an account?",
                                  style: TextStyle(fontSize: 16.0),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.all(5),
                                    splashFactory: NoSplash.splashFactory,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    overlayColor: Colors.transparent,
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/loginPage');
                                  },
                                  child: const Text(
                                    "Log In",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 20,
                            ), // Replace Expanded with SizedBox
                            const Text("Or connect with"),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    // TODO: Google LogIn
                                  },
                                  icon: Image.asset(
                                    'assets/images/icons/login_signup_pages/google.png',
                                    height: 40.0,
                                    width: 40.0,
                                  ),
                                ),
                                const SizedBox(
                                  height: 40,
                                  child: VerticalDivider(
                                    color: Colors.black,
                                    width: 20,
                                    thickness: 2,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    // TODO: Facebook LogIn
                                  },
                                  icon: Image.asset(
                                    'assets/images/icons/login_signup_pages/facebook.png',
                                    height: 40.0,
                                    width: 40.0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(flex: 1, child: Container()), // Flexible spacing
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

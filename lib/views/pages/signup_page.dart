import 'package:flutter/material.dart';
import 'package:later/views/widgets/login_signup_pages/login_with_social.dart';
import 'package:later/views/widgets/login_signup_pages/registration_input_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:later/views/widgets/login_signup_pages/submit_button.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final nickanameController = TextEditingController();

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
                                RegistrationInputField(
                                  controller: nameController,
                                  textHint: "Name",
                                ),
                                const SizedBox(height: 10.0),
                                RegistrationInputField(
                                  controller: nickanameController,
                                  textHint: "Nickname",
                                ),
                                const SizedBox(height: 10.0),
                                RegistrationInputField(
                                  controller: emailController,
                                  textHint: "Email",
                                ),
                                const SizedBox(height: 10.0),
                                RegistrationInputField(
                                  controller: passwordController,
                                  textHint: "Password",
                                  isTextHidden: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 50),
                            SubmitButton(buttonText: 'Sign Up',),
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
                           LoginWithSocial(),
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

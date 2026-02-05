import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:later/views/widgets/auth/login_with_social.dart';
import 'package:later/views/widgets/auth/main_text_and_logo.dart';
import 'package:later/views/widgets/auth/registration_input_field.dart';
import 'package:later/views/widgets/auth/submit_button.dart';
import 'package:later/views/widgets/auth/password_reset_dialog.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(flex: 1, child: Container()),
                      Column(
                        children: [
                          MainText(
                            mainText: 'Log In Now',
                            additionalText:
                                'Please log in to continue using our app',
                          ),
                          SizedBox(height: 30),
                          Column(
                            children: [
                              RegistrationInputField(
                                textHint: "Email",
                                controller: emailController,
                              ),
                              SizedBox(height: 10),
                              RegistrationInputField(
                                textHint: "Password",
                                isTextHidden: true,
                                controller: passwordController,
                              ),
                              SizedBox(height: 2),
                              Container(
                                width: 325,
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    splashFactory: NoSplash.splashFactory,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    overlayColor: Colors.transparent,
                                  ),
                                  onPressed: () {
                                    showPasswordResetDialog(
                                      context,
                                      initialEmail: emailController.text,
                                      onSubmit: (email) async {
                                        try {
                                          await FirebaseAuth.instance
                                              .sendPasswordResetEmail(
                                                email: email,
                                              );
                                        } on FirebaseAuthException catch (e) {
                                          String message;
                                          if (e.code == 'user-not-found') {
                                            message =
                                                'No account found with this email';
                                          } else if (e.code ==
                                              'invalid-email') {
                                            message = 'Invalid email address';
                                          } else {
                                            message = 'Error: ${e.message}';
                                          }
                                          throw message;
                                        }
                                      },
                                    );
                                  },
                                  child: Text(
                                    "Forgot password?",
                                    style: TextStyle(
                                      color: Color(0xFF56C92E),
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 25),
                          SubmitButton(
                            buttonText: 'Log In',
                            email: emailController,
                            password: passwordController,
                            isSignUp: false,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?",
                                style: TextStyle(fontSize: 16.0),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.all(5),
                                  splashFactory: NoSplash.splashFactory,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  overlayColor: Colors.transparent,
                                ),
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/signupPage',
                                  );
                                },
                                child: Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 40.0),
                          LoginWithSocial(),
                        ],
                      ),
                      Expanded(flex: 1, child: Container()),
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

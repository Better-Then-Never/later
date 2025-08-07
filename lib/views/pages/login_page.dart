import 'package:flutter/material.dart';
import 'package:later/views/widgets/login_signup_pages/login_with_social.dart';
import 'package:later/views/widgets/login_signup_pages/main_text_and_logo.dart';
import 'package:later/views/widgets/login_signup_pages/registration_input_field.dart';
import 'package:later/views/widgets/login_signup_pages/submit_button.dart';

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
                                    // TODO: Password reset
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
                          SubmitButton(buttonText: 'Log In'),
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

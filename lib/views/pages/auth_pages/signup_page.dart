import 'package:flutter/material.dart';
import 'package:later/views/pages/auth_pages/login_page.dart';
import 'package:later/views/widgets/auth/login_with_social.dart';
import 'package:later/views/widgets/auth/main_text_and_logo.dart';
import 'package:later/views/widgets/auth/registration_input_field.dart';
import 'package:later/views/widgets/auth/submit_button.dart';
import 'package:page_transition/page_transition.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final usernameController = TextEditingController();

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
                      Expanded(flex: 1, child: Container()),
                      Column(
                        children: [
                          MainText(
                            mainText: 'Sign Up Now',
                            additionalText:
                                'Please fill the details to create your account',
                          ),
                          SizedBox(height: 17.5),
                          Column(
                            children: [
                              RegistrationInputField(
                                controller: nameController,
                                textHint: "Name",
                              ),
                              const SizedBox(height: 10.0),
                              RegistrationInputField(
                                controller: usernameController,
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
                          const SizedBox(height: 40),
                          SubmitButton(
                            buttonText: 'Sign Up',
                            isSignUp: true,
                            email: emailController,
                            password: passwordController,
                            name: nameController,
                            username: usernameController,
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
                                  Navigator.push(
                                    context,
                                    PageTransition(
                                      type: PageTransitionType.fade,
                                      duration: const Duration(
                                        milliseconds: 10,
                                      ),
                                      reverseDuration: const Duration(
                                        milliseconds: 10,
                                      ),
                                      child: LoginPage(),
                                    ),
                                  );
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
                          const SizedBox(height: 20),
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

import 'package:flutter/material.dart';
import 'package:later/views/widgets/registration_input_field.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F6F6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 55.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(0, 100),
                    child: Column(
                      children: [
                        Image.asset(
                          "assets/images/later_logo.png",
                          height: 150,
                          width: 120,
                        ),
                        SizedBox(height: 22.5),
                        Transform.translate(
                          offset: const Offset(0, -30),
                          child: Column(
                            children: [
                              const Text(
                                'Log In Now',
                                style: TextStyle(
                                  fontSize: 40.0,
                                  fontFamily: 'Irina',
                                  letterSpacing: -1,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Transform.translate(
                                offset: const Offset(0, 0),
                                child: const Text(
                                  'Please log in to continue using our app',
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
                        ),
                        Column(
                          spacing: 0,
                          children: [
                            RegistrationInputField(textHint: "Email"),
                            SizedBox(height: 10),
                            RegistrationInputField(
                              textHint: "Password",
                              isTextHidden: true,
                            ),
                            SizedBox(height: 2),
                            Container(
                              width: 350,
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
                        SizedBox(
                          width: 325,
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
                              backgroundColor: Color(0xFF56C92E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25.0),
                              ),
                            ),
                            child: const Text(
                              'Log In',
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
                            Text("Don't have an account?", style: TextStyle(fontSize: 16.0),),
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.all(5),
                                splashFactory: NoSplash.splashFactory,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                overlayColor: Colors.transparent,
                              ),
                              onPressed: () {
                                // TODO: Push to SignUp page
                              },
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.0
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40.0),
                        Text("Or connect with"),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                //TODO: Google LogIn
                              },
                              icon: Image.asset(
                                'assets/images/icons/login_signup_pages/google.png',
                                height: 40.0,
                                width: 40.0,
                              ),
                            ),
                            SizedBox(
                              height: 40,
                              child: VerticalDivider(
                                color: Colors.black,
                                width: 20,
                                thickness: 2,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                //TODO: Facebook LogIn
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

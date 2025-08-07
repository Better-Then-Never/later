import 'package:flutter/material.dart';

class LoginWithSocial extends StatefulWidget {
  const LoginWithSocial({Key? key}) : super(key: key);

  @override
  _LoginWithSocialState createState() => _LoginWithSocialState();
}

class _LoginWithSocialState extends State<LoginWithSocial> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
    );
  }
}

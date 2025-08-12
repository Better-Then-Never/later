import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginWithSocial extends StatefulWidget {
  const LoginWithSocial({super.key});

  @override
  _LoginWithSocialState createState() => _LoginWithSocialState();
}

class _LoginWithSocialState extends State<LoginWithSocial> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Or connect with"),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () async {
                final gooleSignInResult = await signInWithGoogle(context);
                if (gooleSignInResult != null) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/widgetTree',
                    (route) => false,
                  );
                }
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
    );
  }
}

Future<UserCredential?> signInWithGoogle(BuildContext context) async {
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;
  await googleSignIn.initialize();

  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
        .authenticate();

    // ✅ Handle cancel / abort
    if (googleUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Operation aborted')));
      return null;
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  } on Exception catch (e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
    return null;
  }
}

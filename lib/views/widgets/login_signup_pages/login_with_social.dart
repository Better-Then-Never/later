import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginWithSocial extends StatefulWidget {
  const LoginWithSocial({super.key});

  @override
  State<LoginWithSocial> createState() => _LoginWithSocialState();
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
                if (!context.mounted) return;
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
    // ignore: unnecessary_nullable_for_final_variable_declarations
    final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
        .authenticate();

    if (!context.mounted) return null;
    if (googleUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Operation aborted')));
      return null;
    }

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  } on Exception catch (e) {
    if(!context.mounted) return null;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
    return null;
  }
}

import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:later/services/firebase_auth_service.dart';
import 'package:later/views/pages/auth_pages/permission_gate_page.dart';
import 'package:later/views/pages/core_pages/widget_tree_wrapper_page.dart';
import 'package:provider/provider.dart';

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
                final googleSignInResult = await signInWithGoogle(context);
                if (!context.mounted) return;
                if (googleSignInResult != null) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PermissionGatePage(
                        onAllGranted: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WidgetTreeWrapper(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ),
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
  // Use GoogleSignIn.instance instead of GoogleSignIn()
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  if (!context.mounted) return null;
  final authService = Provider.of<FirebaseAuthService>(context, listen: false);

  try {
    // Initialize GoogleSignIn (required in v7+)
    await googleSignIn.initialize();

    // Sign out first to ensure fresh login
    await googleSignIn.signOut();

    // Use authenticate() instead of signIn()
    if (!context.mounted) return null;
    final GoogleSignInAccount googleUser = await googleSignIn.authenticate(
      scopeHint: ['email'], // Specify required scopes
    );

    // Get authentication - now synchronous in v7+
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // For Firebase, we only need the idToken
    // If you need accessToken for Google APIs, use authorizationClient
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    final user = userCredential.user;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        final googleInfo = user.providerData.firstWhere(
          (info) => info.providerId == 'google.com',
          orElse: () => user.providerData.first,
        );

        await authService.addUserToDatabase(
          uid: user.uid,
          email: googleInfo.email ?? user.email ?? '',
          name: googleInfo.displayName ?? user.displayName ?? '',
          username: (googleInfo.email ?? user.email ?? '')
              .split('@')
              .first
              .toLowerCase(),
        );
      }
    }

    return userCredential;
  } on GoogleSignInException catch (e) {
    // Handle specific GoogleSignIn errors
    if (!context.mounted) return null;
    String errorMessage;
    switch (e.code.name) {
      case 'canceled':
        errorMessage = 'Sign-in was cancelled';
        break;
      case 'interrupted':
        errorMessage = 'Sign-in was interrupted';
        break;
      case 'clientConfigurationError':
        errorMessage = 'Configuration error. Please contact support';
        break;
      default:
        errorMessage = 'Sign-in failed: ${e.description ?? e.code.name}';
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(errorMessage)));
    return null;
  } on Exception catch (e) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
    return null;
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class UserService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  Stream<User?> get userStream => _auth.authStateChanges();
}
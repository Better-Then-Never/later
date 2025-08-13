import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getErrorMessage(e.code));
    }
  }

  Future<void> createUserWithEmailAndPassword(
    String email,
    String password, {
    required String name,
    required String username,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();

    final existing = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: normalizedUsername)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Username already taken');
    }

    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final uid = credential.user!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name.trim(),
      'username': normalizedUsername,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await credential.user!.updateDisplayName(name.trim());

    notifyListeners();
  }

  Future<void> signOut() async {
    return await _firebaseAuth.signOut();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> addUserToDatabase({
    required String uid,
    required String email,
    required String name,
    required String username,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();

    final existing = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: normalizedUsername)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw Exception('Username already taken');
    }

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name.trim(),
      'username': normalizedUsername,
      'createdAt': FieldValue.serverTimestamp(),
    });

    notifyListeners();
  }
}

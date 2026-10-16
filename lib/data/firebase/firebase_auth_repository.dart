import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/app_failure.dart';
import '../../core/logging/app_logger.dart';
import '../repositories/repositories.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  Stream<String?> uidChanges() =>
      _auth.authStateChanges().map((user) => user?.uid).distinct();

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  String? get currentEmail => _auth.currentUser?.email;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(messageFor(e.code), cause: e);
    }
  }

  @override
  Future<String> createAccount(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user!.uid;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(messageFor(e.code), cause: e);
    }
  }

  @override
  Future<SocialSignInResult?> signInWithGoogle() async {
    try {
      // Always show the account picker.
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user!;
      return SocialSignInResult(
        uid: user.uid,
        email: user.email ?? googleUser.email,
        displayName: user.displayName ?? googleUser.displayName ?? '',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(messageFor(e.code), cause: e);
    } catch (e, st) {
      AppLogger.warning('Google sign-in failed', error: e, stackTrace: st);
      throw AuthFailure('Google sign-in failed. Please try again.', cause: e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(switch (e.code) {
        'user-not-found' => 'No account found with this email',
        'invalid-email' => 'Invalid email address',
        _ => messageFor(e.code),
      }, cause: e);
    }
  }

  @override
  Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  @override
  Future<void> deleteCurrentUser() async {
    try {
      await _auth.currentUser?.delete();
    } catch (e, st) {
      AppLogger.warning(
        'Rollback of new account failed',
        error: e,
        stackTrace: st,
      );
      await _auth.signOut();
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Not signed in with Google: nothing to do.
    }
  }

  @override
  bool get hasPassword =>
      _auth.currentUser?.providerData.any(
        (p) => p.providerId == EmailAuthProvider.PROVIDER_ID,
      ) ??
      false;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Please sign in again.');
    return user;
  }

  @override
  Future<bool> reauthenticate({String? password}) async {
    final user = _user;
    try {
      final AuthCredential credential;
      if (password != null) {
        credential = EmailAuthProvider.credential(
          email: user.email ?? '',
          password: password,
        );
      } else {
        await _googleSignIn.signOut();
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return false;
        final googleAuth = await googleUser.authentication;
        credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );
      }
      await user.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(accountMessageFor(e.code), cause: e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(accountMessageFor(e.code), cause: e);
    }
  }

  @override
  Future<void> requestEmailChange(String newEmail) async {
    try {
      await _user.verifyBeforeUpdateEmail(newEmail);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(accountMessageFor(e.code), cause: e);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(accountMessageFor(e.code), cause: e);
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Not signed in with Google: nothing to do.
    }
  }

  /// Messages for changes to a signed-in account (the sign-in wording of
  /// [messageFor] talks about "email or password").
  static String accountMessageFor(String code) => switch (code) {
    'wrong-password' ||
    'invalid-credential' ||
    'INVALID_LOGIN_CREDENTIALS' => 'Wrong password.',
    'user-mismatch' => 'Please pick the Google account you sign in with.',
    'requires-recent-login' => 'Please confirm it is you and try again.',
    'email-already-in-use' => 'Another account already uses this email.',
    _ => messageFor(code),
  };

  /// User-facing messages for Firebase Auth error codes. The first five keep
  /// the original wording.
  static String messageFor(String code) => switch (code) {
    'user-not-found' => 'No user found with this email.',
    'wrong-password' => 'Wrong password provided.',
    'invalid-credential' ||
    'INVALID_LOGIN_CREDENTIALS' => 'Wrong email or password.',
    'email-already-in-use' => 'The account already exists for that email.',
    'weak-password' => 'The password provided is too weak.',
    'invalid-email' => 'The email address is not valid.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' => 'No connection. Please try again.',
    'operation-not-allowed' => 'This sign-in method is not enabled.',
    _ => 'An error occurred. Please try again.',
  };
}

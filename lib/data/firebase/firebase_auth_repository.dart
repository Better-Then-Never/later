import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
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
      throw AuthFailure(AppL10n.current.authGoogleFailed, cause: e);
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(switch (e.code) {
        'user-not-found' => AppL10n.current.authResetUserNotFound,
        'invalid-email' => AppL10n.current.authResetInvalidEmail,
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

  @override
  bool get hasGoogle =>
      _auth.currentUser?.providerData.any(
        (p) => p.providerId == GoogleAuthProvider.PROVIDER_ID,
      ) ??
      false;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw AuthFailure(AppL10n.current.authSignInAgain);
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
  static String accountMessageFor(String code) {
    final l10n = AppL10n.current;
    return switch (code) {
      'wrong-password' ||
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' => l10n.authErrorWrongPassword,
      'user-mismatch' => l10n.authErrorPickGoogleAccount,
      'requires-recent-login' => l10n.authErrorRecentLogin,
      'email-already-in-use' => l10n.authErrorEmailTaken,
      _ => messageFor(code),
    };
  }

  /// User-facing messages for Firebase Auth error codes, in the app's
  /// language. The first five keep the original English wording.
  static String messageFor(String code) {
    final l10n = AppL10n.current;
    return switch (code) {
      'user-not-found' => l10n.authErrorUserNotFound,
      'wrong-password' => l10n.authErrorWrongPasswordProvided,
      'invalid-credential' ||
      'INVALID_LOGIN_CREDENTIALS' => l10n.authErrorInvalidCredential,
      'email-already-in-use' => l10n.authErrorEmailInUse,
      'weak-password' => l10n.authErrorWeakPassword,
      'invalid-email' => l10n.authErrorInvalidEmail,
      'user-disabled' => l10n.authErrorUserDisabled,
      'too-many-requests' => l10n.authErrorTooManyRequests,
      'network-request-failed' => l10n.commonNoConnection,
      'operation-not-allowed' => l10n.authErrorMethodDisabled,
      _ => l10n.commonErrorGeneric,
    };
  }
}

import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';

/// Login, signup, Google sign-in and password reset. Each method returns
/// null on success or the failure to show; navigation is left to the UI.
class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository auth, required UserRepository users})
    : _auth = auth,
      _users = users;

  final AuthRepository _auth;
  final UserRepository _users;

  bool _busy = false;
  bool _disposed = false;
  bool get busy => _busy;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<AppFailure?> _run(Future<void> Function() action) async {
    if (_busy) return null;
    _busy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } on AppFailure catch (f) {
      return f;
    } catch (e, st) {
      AppLogger.error('Auth action failed', error: e, stackTrace: st);
      return AppFailure.from(e);
    } finally {
      _busy = false;
      // A successful sign-in replaces the page (and disposes this
      // controller) before the action returns.
      if (!_disposed) notifyListeners();
    }
  }

  Future<AppFailure?> login({required String email, required String password}) {
    if (email.trim().isEmpty || password.isEmpty) {
      return Future.value(ValidationFailure(AppL10n.current.authFillAllFields));
    }
    return _run(() => _auth.signInWithEmail(email.trim(), password));
  }

  Future<AppFailure?> signUp({
    required String name,
    required String username,
    required String email,
    required String password,
  }) {
    final trimmedName = name.trim();
    final normalized = Usernames.normalize(username);
    if (trimmedName.isEmpty ||
        normalized.isEmpty ||
        email.trim().isEmpty ||
        password.isEmpty) {
      return Future.value(ValidationFailure(AppL10n.current.authFillAllFields));
    }
    final invalid = Usernames.validate(normalized);
    if (invalid != null) return Future.value(ValidationFailure(invalid));

    return _run(() async {
      final uid = await _auth.createAccount(email.trim(), password);
      try {
        await _users.createProfile(
          uid: uid,
          name: trimmedName,
          username: normalized,
        );
        await _auth.updateDisplayName(trimmedName);
      } catch (_) {
        // Never leave an account without a profile behind (BUG-009).
        await _auth.deleteCurrentUser();
        rethrow;
      }
    });
  }

  /// Returns null on success *or* when the user cancelled the Google dialog.
  Future<AppFailure?> signInWithGoogle() => _run(() async {
    final result = await _auth.signInWithGoogle();
    if (result == null) return;
    try {
      final existing = await _users.getProfile(result.uid);
      if (existing != null) return;
      final username = await _freeUsername(result.email.split('@').first);
      await _users.createProfile(
        uid: result.uid,
        name: result.displayName.trim().isEmpty
            ? username
            : result.displayName.trim(),
        username: username,
      );
    } catch (_) {
      await _auth.signOut();
      rethrow;
    }
  });

  Future<String> _freeUsername(String seed) async {
    final base = Usernames.sanitize(seed);
    if (!await _users.isUsernameTaken(base)) return base;
    final random = Random();
    for (var i = 0; i < 10; i++) {
      final candidate = '$base${random.nextInt(9000) + 1000}';
      if (!await _users.isUsernameTaken(candidate)) return candidate;
    }
    throw ValidationFailure(AppL10n.current.authNoFreeUsername);
  }

  Future<AppFailure?> sendPasswordReset(String email) {
    if (email.trim().isEmpty) {
      return Future.value(ValidationFailure(AppL10n.current.authEnterEmail));
    }
    return _run(() => _auth.sendPasswordReset(email.trim()));
  }
}

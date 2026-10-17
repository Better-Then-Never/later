import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';

/// Saving the editable account fields from the settings pages. Each
/// returns null on success, otherwise a failure with a message for the
/// user.
abstract final class AccountSettings {
  /// Creates the missing profile of a signed-in account (POL-002) with the
  /// same checks as signup.
  static Future<AppFailure?> completeProfile(
    UserRepository users,
    AuthRepository auth,
    String uid, {
    required String name,
    required String username,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return ValidationFailure(AppL10n.current.settingsErrorEnterName);
    }
    final normalized = Usernames.normalize(username);
    final invalid = Usernames.validate(normalized);
    if (invalid != null) return ValidationFailure(invalid);
    try {
      await users.createProfile(
        uid: uid,
        name: trimmedName,
        username: normalized,
      );
      await auth.updateDisplayName(trimmedName);
      return null;
    } catch (e, st) {
      AppLogger.warning(
        'Completing the profile failed',
        error: e,
        stackTrace: st,
      );
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.settingsErrorCouldNotSave,
      );
    }
  }

  static Future<AppFailure?> saveName(
    UserRepository users,
    String uid,
    String input,
  ) async {
    final name = input.trim();
    if (name.isEmpty) {
      return ValidationFailure(AppL10n.current.settingsErrorEnterNewName);
    }
    try {
      await users.updateName(uid, name);
      return null;
    } catch (e, st) {
      AppLogger.warning('Updating the name failed', error: e, stackTrace: st);
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.settingsErrorNameFailed,
      );
    }
  }

  /// Lower-cases and validates the username, then changes it in one
  /// transaction that also moves the `usernames/{name}` reservation, so two
  /// users can never end up with the same username (BUG-083).
  static Future<AppFailure?> saveUsername(
    UserRepository users,
    String uid,
    String input,
  ) async {
    if (input.trim().isEmpty) {
      return ValidationFailure(AppL10n.current.settingsErrorEnterNewUsername);
    }
    final username = Usernames.normalize(input);
    final invalid = Usernames.validate(username);
    if (invalid != null) return ValidationFailure(invalid);
    try {
      await users.changeUsername(uid, username);
      return null;
    } catch (e, st) {
      AppLogger.warning(
        'Updating the username failed',
        error: e,
        stackTrace: st,
      );
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.settingsErrorUsernameFailed,
      );
    }
  }
}

/// Password, email and account deletion. Firebase wants a recent sign-in
/// for each, so every action confirms the user's identity first: with the
/// current password for email accounts, with the Google account picker for
/// Google-only ones. Each returns null on success, [CancelledFailure] when
/// the user closed the picker, otherwise a failure with a message.
abstract final class AccountSecurity {
  static const minPasswordLength = 6;

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static Future<AppFailure?> changePassword(
    AuthRepository auth, {
    required String current,
    required String next,
    required String confirm,
  }) async {
    final l10n = AppL10n.current;
    if (current.isEmpty) {
      return ValidationFailure(l10n.settingsErrorCurrentPassword);
    }
    if (next.length < minPasswordLength) {
      return ValidationFailure(
        l10n.settingsErrorPasswordTooShort(minPasswordLength),
      );
    }
    if (next != confirm) {
      return ValidationFailure(l10n.settingsErrorPasswordsMismatch);
    }
    if (next == current) {
      return ValidationFailure(l10n.settingsErrorPasswordSame);
    }
    return _run('Changing the password', () async {
      await auth.reauthenticate(password: current);
      await auth.updatePassword(next);
    });
  }

  /// Sends the confirmation link to [newEmail]; the sign-in email changes
  /// when the user opens it.
  static Future<AppFailure?> changeEmail(
    AuthRepository auth, {
    required String newEmail,
    String? password,
  }) async {
    final email = newEmail.trim();
    if (!_email.hasMatch(email)) {
      return ValidationFailure(AppL10n.current.settingsErrorInvalidEmail);
    }
    if (email.toLowerCase() == auth.currentEmail?.toLowerCase()) {
      return ValidationFailure(AppL10n.current.settingsErrorSameEmail);
    }
    if (auth.hasPassword && (password == null || password.isEmpty)) {
      return ValidationFailure(AppL10n.current.settingsErrorEnterPassword);
    }
    return _run('Changing the email', () async {
      if (!await auth.reauthenticate(
        password: auth.hasPassword ? password : null,
      )) {
        throw const CancelledFailure();
      }
      await auth.requestEmailChange(email);
    });
  }

  /// Deletes the account after confirming the user's identity.
  static Future<AppFailure?> deleteAccount(
    AuthRepository auth,
    Future<void> Function() delete, {
    String? password,
  }) async {
    if (auth.hasPassword && (password == null || password.isEmpty)) {
      return ValidationFailure(AppL10n.current.settingsErrorEnterPassword);
    }
    return _run('Deleting the account', () async {
      if (!await auth.reauthenticate(
        password: auth.hasPassword ? password : null,
      )) {
        throw const CancelledFailure();
      }
      await delete();
    });
  }

  static Future<AppFailure?> _run(
    String what,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      return null;
    } on CancelledFailure catch (e) {
      return e;
    } catch (e, st) {
      AppLogger.warning('$what failed', error: e, stackTrace: st);
      return AppFailure.from(e);
    }
  }
}

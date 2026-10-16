import '../../core/errors/app_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';

/// Saving the editable account fields from the settings pages. Each
/// returns null on success, otherwise a failure with a message for the
/// user.
abstract final class AccountSettings {
  static Future<AppFailure?> saveName(
    UserRepository users,
    String uid,
    String input,
  ) async {
    final name = input.trim();
    if (name.isEmpty) {
      return const ValidationFailure('Please enter a new name!');
    }
    try {
      await users.updateName(uid, name);
      return null;
    } catch (e, st) {
      AppLogger.warning('Updating the name failed', error: e, stackTrace: st);
      return AppFailure.from(e, fallbackMessage: 'Failed to update name!');
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
      return const ValidationFailure('Please enter a new username!');
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
      return AppFailure.from(e, fallbackMessage: 'Failed to update username!');
    }
  }
}

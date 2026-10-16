import 'package:firebase_core/firebase_core.dart';

/// A failure that can be shown to the user. [message] is always safe to
/// display; [cause] keeps the original error for logging.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  /// Maps any thrown object to an [AppFailure] with a user-facing message.
  static AppFailure from(Object error, {String? fallbackMessage}) {
    if (error is AppFailure) return error;
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
        case 'unauthenticated':
          return PermissionFailure(
            'You are not allowed to do that.',
            cause: error,
          );
        case 'unavailable':
        case 'network-request-failed':
        case 'deadline-exceeded':
          return NetworkFailure(
            'No connection. Please try again.',
            cause: error,
          );
        case 'not-found':
        case 'object-not-found':
          return NotFoundFailure(
            fallbackMessage ?? 'This item no longer exists.',
            cause: error,
          );
      }
    }
    return UnknownFailure(
      fallbackMessage ?? 'Something went wrong. Please try again.',
      cause: error,
    );
  }

  @override
  String toString() => message;
}

final class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.cause});
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.cause});
}

final class PermissionFailure extends AppFailure {
  const PermissionFailure(super.message, {super.cause});
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message, {super.cause});
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message, {super.cause});
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(super.message, {super.cause});
}

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// App-wide logging. Replaces `print`. Debug messages are dropped in release
/// builds; secrets (tokens) must be passed through [redact].
abstract final class AppLogger {
  static void debug(String message, {String tag = 'later'}) {
    if (kReleaseMode) return;
    developer.log(message, name: tag, level: 500);
  }

  static void info(String message, {String tag = 'later'}) {
    developer.log(message, name: tag, level: 800);
  }

  static void warning(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String tag = 'later',
  }) {
    developer.log(
      message,
      name: tag,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String tag = 'later',
  }) {
    developer.log(
      message,
      name: tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Shortens a secret so it can be logged for correlation only.
  static String redact(String? secret) {
    if (secret == null || secret.isEmpty) return '<none>';
    final visible = secret.length < 6 ? secret.length : 6;
    return '${secret.substring(0, visible)}…';
  }
}

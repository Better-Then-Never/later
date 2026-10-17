import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/logging/app_logger.dart';

/// Uploads of waiting capsules while the app is closed (B4): Android's
/// WorkManager runs a job (UploadWorker.kt) once a network is there (Wi-Fi
/// with "Upload on Wi-Fi only"), with its own growing waits between
/// attempts. The job starts backgroundUploadsMain
/// (app/background_uploads_main.dart) in a Flutter engine of its own.
/// Android only; elsewhere the app uploads when it is open.
class BackgroundUploads {
  BackgroundUploads({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('later.app/uploads');

  final MethodChannel _channel;

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Whether this phone runs the job (tests say yes off Android).
  bool get enabled => isSupported;

  /// Asks for one run (replacing an earlier request).
  Future<void> schedule({required bool wifiOnly}) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('schedule', {'wifiOnly': wifiOnly});
    } catch (e) {
      AppLogger.warning('Background uploads not scheduled', error: e);
    }
  }

  /// The app is open again (it uploads by itself) or nothing waits.
  Future<void> cancel() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('cancel');
    } catch (e) {
      AppLogger.warning('Background uploads not cancelled', error: e);
    }
  }
}

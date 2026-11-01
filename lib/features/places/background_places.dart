import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';

/// The place alerts' check while the app is closed (capsule v3 phase 4):
/// Android's WorkManager runs it about every half hour (PlacesWorker.kt) in
/// a Flutter engine of its own (app/background_places_main.dart), while
/// "Capsules near you" or "Welcome to a new country" is on. Android only.
class BackgroundPlaces {
  BackgroundPlaces({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('later.app/places');

  final MethodChannel _channel;

  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Starts the half-hourly check (kept when it already runs).
  Future<void> schedule() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('schedule');
    } catch (e) {
      AppLogger.warning('Place alerts not scheduled', error: e);
    }
  }

  /// Both alerts are off.
  Future<void> cancel() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('cancel');
    } catch (e) {
      AppLogger.warning('Place alerts not cancelled', error: e);
    }
  }
}

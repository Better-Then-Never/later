import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';

/// Saves capsule photos to the phone's gallery (Pictures/Later) through the
/// app's own channel (android/.../GalleryChannel.kt). Android 10 and later
/// only; elsewhere the setting is not offered.
class GalleryService {
  GalleryService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('later.app/gallery');

  final MethodChannel _channel;

  /// Whether this phone can save to the gallery (Android; the native side
  /// still answers false below Android 10).
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  /// Copies the JPEG at [path] into the gallery as [name]. False when the
  /// phone cannot or the copy failed (logged, never thrown: a capsule is
  /// already made when this runs).
  Future<bool> save(String path, {required String name}) async {
    try {
      return await _channel.invokeMethod<bool>('saveImage', {
            'path': path,
            'name': name,
          }) ??
          false;
    } catch (e, st) {
      AppLogger.warning(
        'Saving to the gallery failed',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}

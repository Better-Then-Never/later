import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../core/logging/app_logger.dart';

/// Photos from the network, kept on disk between sessions (F-01, F-02).
///
/// Every picture goes through one cache manager, keyed by its URL (capsule
/// photos never change; a new profile picture gets a new URL, and the app
/// evicts the old one after its own uploads). Decoded sizes come from a few
/// fixed buckets, so a photo shown at slightly different sizes on the map,
/// in the list and in the chat is decoded once, not once per size.
abstract final class AppImageCache {
  static final CacheManager manager = CacheManager(
    Config(
      'later_images',
      stalePeriod: const Duration(days: 60),
      maxNrOfCacheObjects: 800,
    ),
  );

  /// Decode widths in pixels.
  static const buckets = [96, 192, 384, 640, 1080, 1600];

  /// The decode width for a picture [logicalWidth] wide on a screen with
  /// [devicePixelRatio]: the next bucket up.
  static int decodeWidth(double logicalWidth, double devicePixelRatio) {
    final pixels = logicalWidth * devicePixelRatio;
    for (final b in buckets) {
      if (b >= pixels) return b;
    }
    return buckets.last;
  }

  /// [url] from the disk cache (downloaded once), decoded at [width] pixels.
  static ImageProvider provider(String url, {int? width}) =>
      ResizeImage.resizeIfNeeded(
        width,
        null,
        CachedNetworkImageProvider(url, cacheManager: manager),
      );

  /// Puts a picture the app just uploaded into the cache under its URL, so
  /// showing it later reads the disk instead of downloading it again.
  static Future<void> seed(String url, List<int> bytes) async {
    try {
      await manager.putFile(
        url,
        Uint8List.fromList(bytes),
        fileExtension: 'jpg',
      );
    } catch (e) {
      AppLogger.debug('Could not cache $url: $e');
    }
  }

  /// Forget one picture (the user replaced or deleted it).
  static Future<void> evict(String url) async {
    try {
      await CachedNetworkImageProvider(url, cacheManager: manager).evict();
      await manager.removeFile(url);
    } catch (e) {
      AppLogger.debug('Could not evict $url: $e');
    }
  }

  /// Empties the disk cache (Settings > Data and storage).
  static Future<void> clear() async {
    try {
      await manager.emptyCache();
    } catch (e) {
      AppLogger.warning('Could not empty the image cache', error: e);
    }
  }
}

import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';

/// Files the app can always make again: photos taken or picked for a
/// capsule or a profile picture, shared QR images (all in the temporary
/// directory), and pictures held in memory.
class CacheService {
  CacheService({Future<Directory> Function()? directory})
    : _directory = directory ?? getTemporaryDirectory;

  final Future<Directory> Function() _directory;

  /// Bytes on disk plus decoded pictures in memory.
  Future<int> size() async {
    var total = PaintingBinding.instance.imageCache.currentSizeBytes;
    try {
      final dir = await _directory();
      if (!dir.existsSync()) return total;
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          try {
            total += await entity.length();
          } on FileSystemException {
            // Removed while counting.
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Could not measure the cache', error: e);
    }
    return total;
  }

  /// Deletes everything in the cache; files in use are skipped.
  Future<void> clear() async {
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    try {
      final dir = await _directory();
      if (!dir.existsSync()) return;
      await for (final entity in dir.list(followLinks: false)) {
        try {
          await entity.delete(recursive: true);
        } on FileSystemException catch (e) {
          AppLogger.warning('Could not delete ${entity.path}', error: e);
        }
      }
    } catch (e) {
      AppLogger.warning('Could not clear the cache', error: e);
    }
  }

  /// "0 B", "512 KB", "3.4 MB" (units and decimal comma follow the app's
  /// language: "3,4 МБ").
  static String format(int bytes) {
    final l10n = AppL10n.current;
    final whole = NumberFormat.decimalPattern(l10n.localeName);
    final tenth = NumberFormat('0.0', l10n.localeName);
    if (bytes < 1024) return l10n.commonSizeBytes(whole.format(bytes));
    if (bytes < 1024 * 1024) {
      return l10n.commonSizeKilobytes(whole.format((bytes / 1024).round()));
    }
    if (bytes < 1024 * 1024 * 1024) {
      return l10n.commonSizeMegabytes(tenth.format(bytes / (1024 * 1024)));
    }
    return l10n.commonSizeGigabytes(tenth.format(bytes / (1024 * 1024 * 1024)));
  }
}

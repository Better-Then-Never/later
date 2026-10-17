import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/profile_image_cache.dart';

/// Upload / delete of the signed-in user's profile or background picture.
///
/// Replaces AssetImageService (BUG-080): pictures are cropped, resized and
/// JPEG-compressed in an isolate by the repository and stored with a content
/// type; nothing is copied into SharedPreferences; the shared
/// [ProfileImageCache] is invalidated so every avatar of this user updates.
/// Delete never leaves the widget stuck in "Updating..." (BUG-081).
class ProfileImageEditor extends ChangeNotifier {
  ProfileImageEditor({
    required this.uid,
    required this.kind,
    required ImageStorageRepository images,
    required ProfileImageCache cache,
  }) : _images = images,
       _cache = cache;

  final String uid;
  final ProfileImageKind kind;
  final ImageStorageRepository _images;
  final ProfileImageCache _cache;

  bool _busy = false;
  Uint8List? _preview;
  bool _disposed = false;

  bool get isBusy => _busy;

  /// The picture just uploaded, shown until the new URL has loaded.
  Uint8List? get preview => _preview;

  Future<AppFailure?> upload(Uint8List bytes) => _run(
    kind == ProfileImageKind.profile
        ? 'Failed to upload profile picture'
        : 'Failed to upload background picture',
    kind == ProfileImageKind.profile
        ? AppL10n.current.profileErrorUploadPicture
        : AppL10n.current.profileErrorUploadBackground,
    () async {
      if (kind == ProfileImageKind.profile) {
        await _images.uploadProfileImage(uid, bytes);
      } else {
        await _images.uploadBackgroundImage(uid, bytes);
      }
      _preview = bytes;
    },
  );

  Future<AppFailure?> delete() => _run(
    kind == ProfileImageKind.profile
        ? 'Failed to delete profile picture'
        : 'Failed to delete background picture',
    kind == ProfileImageKind.profile
        ? AppL10n.current.profileErrorDeletePicture
        : AppL10n.current.profileErrorDeleteBackground,
    () async {
      await _images.deleteImage(uid, kind);
      _preview = null;
    },
  );

  /// [logMessage] goes to the log (English); [fallbackMessage] is shown to
  /// the user in the app's language.
  Future<AppFailure?> _run(
    String logMessage,
    String fallbackMessage,
    Future<void> Function() action,
  ) async {
    if (_busy) return null;
    _busy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } catch (e, st) {
      AppLogger.warning(logMessage, error: e, stackTrace: st);
      return AppFailure.from(e, fallbackMessage: fallbackMessage);
    } finally {
      _cache.invalidate(uid, kind: kind);
      _busy = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

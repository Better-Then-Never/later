import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/models/user_settings.dart';
import '../../data/repositories/repositories.dart';

/// The signed-in user's account settings (notification preferences, muted
/// chats), live from `users/{uid}/settings/app`.
///
/// Changes apply at once and roll back if the save fails. The Cloud
/// Functions read the same document before every push.
class SettingsStore extends ChangeNotifier implements SessionScoped {
  SettingsStore(this._repo, {int Function()? utcOffsetMinutes})
    : _utcOffset =
          utcOffsetMinutes ?? (() => DateTime.now().timeZoneOffset.inMinutes);

  final SettingsRepository _repo;
  final int Function() _utcOffset;

  StreamSubscription<UserSettings>? _sub;
  String? _uid;
  UserSettings _settings = const UserSettings();
  bool _loaded = false;
  bool _offsetChecked = false;

  UserSettings get settings => _settings;
  NotificationSettings get notifications => _settings.notifications;
  Set<String> get mutedChats => _settings.mutedChats;
  bool get isLoaded => _loaded;
  bool isMuted(String chatId) => _settings.mutedChats.contains(chatId);

  @override
  void attach(String uid) {
    _uid = uid;
    _sub = _repo
        .watch(uid)
        .listen(
          (settings) {
            _settings = settings;
            _loaded = true;
            notifyListeners();
            _syncUtcOffset();
          },
          onError: (Object e, StackTrace st) {
            // Defaults stay in place; the server applies the same ones.
            AppLogger.warning(
              'Settings stream failed',
              error: e,
              stackTrace: st,
            );
            _loaded = true;
            notifyListeners();
          },
        );
  }

  @override
  void detach() {
    unawaited(_sub?.cancel());
    _sub = null;
    _uid = null;
    _settings = const UserSettings();
    _loaded = false;
    _offsetChecked = false;
    notifyListeners();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}

  /// Saves [next]; returns null on success, otherwise the failure (the
  /// previous settings are back in place).
  Future<AppFailure?> updateNotifications(NotificationSettings next) async {
    final uid = _uid;
    if (uid == null) {
      return PermissionFailure(AppL10n.current.settingsErrorSignInAgain);
    }
    final previous = _settings;
    final withOffset = next.copyWith(utcOffsetMinutes: _utcOffset());
    _settings = _settings.copyWith(notifications: withOffset);
    notifyListeners();
    try {
      await _repo.saveNotifications(uid, withOffset);
      return null;
    } catch (e, st) {
      AppLogger.warning('Saving settings failed', error: e, stackTrace: st);
      if (_uid == uid) {
        _settings = previous;
        notifyListeners();
      }
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.settingsErrorSaveFailed,
      );
    }
  }

  /// Mutes or unmutes pushes (and the unread badge) for [chatId].
  Future<AppFailure?> setChatMuted(String chatId, {required bool muted}) async {
    final uid = _uid;
    if (uid == null) {
      return PermissionFailure(AppL10n.current.settingsErrorSignInAgain);
    }
    final previous = _settings;
    _settings = _settings.copyWith(
      mutedChats: muted
          ? {..._settings.mutedChats, chatId}
          : ({..._settings.mutedChats}..remove(chatId)),
    );
    notifyListeners();
    try {
      await _repo.setChatMuted(uid, chatId, muted: muted);
      return null;
    } catch (e, st) {
      AppLogger.warning('Muting the chat failed', error: e, stackTrace: st);
      if (_uid == uid) {
        _settings = previous;
        notifyListeners();
      }
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.settingsErrorChatUpdateFailed,
      );
    }
  }

  /// Quiet hours are in local time: when the device's offset changed since
  /// they were saved (travel, daylight saving), save the new offset once.
  void _syncUtcOffset() {
    if (_offsetChecked) return;
    _offsetChecked = true;
    final n = _settings.notifications;
    final offset = _utcOffset();
    if (!n.quietHours.enabled || n.utcOffsetMinutes == offset) return;
    unawaited(updateNotifications(n));
  }
}

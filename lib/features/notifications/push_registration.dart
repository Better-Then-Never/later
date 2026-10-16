import 'dart:async';
import 'dart:io';

import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/push_messaging_service.dart';

/// Keeps this device's FCM token registered for the signed-in user only.
///
/// - sign-in: the token is saved (BUG-021: it used to be saved only if a user
///   was already signed in at cold start);
/// - token refresh: the new token is saved;
/// - sign-out: the token document is removed and the token revoked while the
///   user is still authenticated (BUG-022).
class PushRegistration implements SessionScoped {
  PushRegistration({
    required PushMessagingService push,
    required PushTokenRepository tokens,
  }) : _push = push,
       _tokens = tokens;

  final PushMessagingService _push;
  final PushTokenRepository _tokens;

  StreamSubscription<String>? _refreshSub;
  String? _uid;
  String? _token;

  @override
  void attach(String uid) {
    _uid = uid;
    unawaited(_register(uid));
  }

  Future<void> _register(String uid) async {
    await _push.initialize();
    // iOS only registers with APNs through FCM's permission call (a no-op
    // when the user already answered the permission gate). Android gets a
    // token without it.
    if (Platform.isIOS) await _push.requestPermission();
    final token = await _push.getToken();
    if (token == null || _uid != uid) return;
    _token = token;
    await _save(uid, token);
    _refreshSub = _push.tokenRefreshes.listen((fresh) {
      if (_uid != uid) return;
      _token = fresh;
      unawaited(_save(uid, fresh));
    });
  }

  Future<void> _save(String uid, String token) async {
    try {
      await _tokens.saveToken(uid, token, PushMessagingService.platformName);
      AppLogger.debug('Push token registered (${AppLogger.redact(token)})');
    } catch (e) {
      AppLogger.warning('Could not save the push token', error: e);
    }
  }

  @override
  Future<void> beforeSignOut(String uid) async {
    final token = _token;
    if (token == null) return;
    try {
      await _tokens.deleteToken(uid, token);
    } catch (e) {
      AppLogger.warning('Could not remove the push token', error: e);
    }
    await _push.deleteToken();
    _token = null;
  }

  @override
  void detach() {
    unawaited(_refreshSub?.cancel());
    _refreshSub = null;
    _uid = null;
    _token = null;
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';

/// Ids of the capsules the signed-in user marked as favourite
/// (`users/{uid}.favorites`), live.
///
/// Fixes BUG-066: a toggle shows immediately and is rolled back when the
/// write fails; the write merges, so it also works without a user document.
class FavoritesStore extends ChangeNotifier implements SessionScoped {
  FavoritesStore(this._users);

  final UserRepository _users;

  StreamSubscription<UserProfile?>? _sub;
  String? _uid;
  Set<String> _server = const {};

  /// Optimistic values not yet confirmed by the server.
  final Map<String, bool> _pending = {};

  bool isFavorite(String capsuleId) =>
      _pending[capsuleId] ?? _server.contains(capsuleId);

  Set<String> get favorites => {
    for (final id in {..._server, ..._pending.keys})
      if (isFavorite(id)) id,
  };

  @override
  void attach(String uid) {
    _uid = uid;
    _sub = _users.watchProfile(uid).listen(
      (profile) {
        _server = profile?.favorites ?? const {};
        _pending.removeWhere((id, value) => _server.contains(id) == value);
        notifyListeners();
      },
      onError: (Object e, StackTrace st) => AppLogger.warning(
        'Favorites stream failed',
        error: e,
        stackTrace: st,
      ),
    );
  }

  @override
  void detach() {
    unawaited(_sub?.cancel());
    _sub = null;
    _uid = null;
    _server = const {};
    _pending.clear();
    notifyListeners();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}

  /// Flips the favourite state of [capsuleId]. Returns null on success, the
  /// failure (after restoring the previous state) otherwise.
  Future<AppFailure?> toggle(String capsuleId) async {
    final uid = _uid;
    if (uid == null) return null;
    final next = !isFavorite(capsuleId);
    _pending[capsuleId] = next;
    notifyListeners();
    try {
      await _users.setFavorite(uid, capsuleId, next);
      return null;
    } catch (e, st) {
      AppLogger.warning('Updating favourites failed', error: e, stackTrace: st);
      if (_uid == uid && _pending[capsuleId] == next) {
        _pending.remove(capsuleId);
        notifyListeners();
      }
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.historyErrorFavorites,
      );
    }
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/session/session_scoped.dart';
import '../../core/logging/app_logger.dart';
import '../repositories/repositories.dart';

/// Resolves and caches profile/background picture URLs for any user.
///
/// Replaces four separate caches that never forgot a "no picture" answer:
/// misses expire after [missTtl], the signed-in user's own entries are
/// invalidated right after an upload or delete, and everything is cleared
/// when the user signs out.
class ProfileImageCache extends ChangeNotifier implements SessionScoped {
  ProfileImageCache(this._repo, {this.missTtl = const Duration(minutes: 10)});

  final ImageStorageRepository _repo;
  final Duration missTtl;

  final Map<String, _Entry> _entries = {};

  static String _key(String uid, ProfileImageKind kind, bool small) =>
      '$uid/${kind.name}/${small ? 's' : 'l'}';

  /// The cached URL, or null when unknown/absent. Starts a lookup when the
  /// value is not cached yet; listeners are notified when it resolves.
  String? url(String uid, ProfileImageKind kind, {bool small = true}) {
    if (uid.isEmpty) return null;
    final key = _key(uid, kind, small);
    final entry = _entries[key];
    if (entry == null || entry.isExpired(missTtl)) {
      unawaited(_load(key, uid, kind, small));
    }
    return entry?.url;
  }

  /// Whether a lookup finished for this image (with or without a result).
  bool isResolved(String uid, ProfileImageKind kind, {bool small = true}) =>
      _entries[_key(uid, kind, small)]?.resolved ?? false;

  Future<String?> resolve(
    String uid,
    ProfileImageKind kind, {
    bool small = true,
  }) async {
    final key = _key(uid, kind, small);
    final entry = _entries[key];
    if (entry != null && entry.resolved && !entry.isExpired(missTtl)) {
      return entry.url;
    }
    return _load(key, uid, kind, small);
  }

  final Map<String, Future<String?>> _inFlight = {};

  Future<String?> _load(
    String key,
    String uid,
    ProfileImageKind kind,
    bool small,
  ) {
    return _inFlight[key] ??= () async {
      String? url;
      try {
        url = await _repo.imageUrl(uid, kind, small: small);
      } catch (e) {
        AppLogger.debug('Image lookup failed for $key: $e');
      }
      _inFlight.remove(key);
      _entries[key] = _Entry(url, DateTime.now());
      notifyListeners();
      return url;
    }();
  }

  /// Forget [uid]'s pictures of [kind] (all kinds when null), after an
  /// upload or delete. Other kinds stay cached so they do not flicker.
  void invalidate(String uid, {ProfileImageKind? kind}) {
    final prefix = kind == null ? '$uid/' : '$uid/${kind.name}/';
    _entries.removeWhere((key, _) => key.startsWith(prefix));
    notifyListeners();
  }

  @override
  void attach(String uid) {}

  @override
  void detach() {
    _entries.clear();
    notifyListeners();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}
}

class _Entry {
  _Entry(this.url, this.fetchedAt);

  final String? url;
  final DateTime fetchedAt;

  bool get resolved => true;

  /// Hits are kept for the session; misses are retried after [ttl].
  bool isExpired(Duration ttl) =>
      url == null && DateTime.now().difference(fetchedAt) > ttl;
}

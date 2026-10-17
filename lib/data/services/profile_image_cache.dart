import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/session/session_scoped.dart';
import '../../core/logging/app_logger.dart';
import '../repositories/repositories.dart';
import 'app_image_cache.dart';
import 'preferences_store.dart';

/// Resolves and caches profile/background picture URLs for any user.
///
/// Replaces four separate caches that never forgot a "no picture" answer:
/// misses expire after [missTtl], the signed-in user's own entries are
/// invalidated right after an upload or delete, and everything is cleared
/// when the user signs out.
///
/// With [prefs], the URLs found are remembered on this phone for the
/// signed-in user (F-02): after a restart pictures show at once from the
/// disk cache, and each is looked up again once per session in the
/// background in case it changed.
class ProfileImageCache extends ChangeNotifier implements SessionScoped {
  ProfileImageCache(
    this._repo, {
    this.missTtl = const Duration(minutes: 10),
    PreferencesStore? prefs,
    Future<void> Function(String url)? evict,
  }) : _prefs = prefs,
       _evict = evict ?? AppImageCache.evict;

  final ImageStorageRepository _repo;
  final Duration missTtl;
  final PreferencesStore? _prefs;

  /// Drops a replaced picture from the photo cache.
  final Future<void> Function(String url) _evict;

  static const _prefsName = 'image_urls';
  static const _maxRemembered = 400;
  String? _uid;
  Timer? _saveTimer;

  final Map<String, _Entry> _entries = {};

  static String _key(String uid, ProfileImageKind kind, bool small) =>
      '$uid/${kind.name}/${small ? 's' : 'l'}';

  /// The cached URL, or null when unknown/absent. Starts a lookup when the
  /// value is not cached yet; listeners are notified when it resolves.
  String? url(String uid, ProfileImageKind kind, {bool small = true}) {
    if (uid.isEmpty) return null;
    final key = _key(uid, kind, small);
    final entry = _entries[key];
    if (entry == null || entry.isExpired(missTtl) || entry.remembered) {
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
    if (entry != null &&
        entry.resolved &&
        !entry.remembered &&
        !entry.isExpired(missTtl)) {
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
    final generation = _generation;
    return _inFlight[key] ??= () async {
      String? url;
      var failed = false;
      try {
        url = await _repo.imageUrl(uid, kind, small: small);
      } catch (e) {
        failed = true;
        AppLogger.debug('Image lookup failed for $key: $e');
      }
      // Started in another session (e.g. while signing out, when Storage
      // refuses every read): its answer must not reach the next one.
      if (generation != _generation) return url;
      // The removed future is this very lookup; nothing to wait for.
      _inFlight.remove(key)?.ignore();
      final previous = _entries[key];
      // Offline after a restart: keep showing the remembered picture.
      if (failed && previous != null && previous.url != null) {
        _entries[key] = _Entry(previous.url, DateTime.now());
        return previous.url;
      }
      _entries[key] = _Entry(url, DateTime.now(), failed: failed);
      if (previous?.url != null && previous!.url != url) {
        unawaited(_evict(previous.url!));
      }
      if (previous == null || previous.url != url) notifyListeners();
      _scheduleSave();
      return url;
    }();
  }

  Future<void> _restore(String uid) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final generation = _generation;
    final raw = await prefs.string(uid, _prefsName);
    if (raw == null || generation != _generation) return;
    try {
      final saved = jsonDecode(raw);
      if (saved is! Map) return;
      for (final e in saved.entries) {
        if (e.key is String && e.value is String) {
          _entries.putIfAbsent(
            e.key as String,
            () => _Entry(e.value as String, DateTime.now(), remembered: true),
          );
        }
      }
      notifyListeners();
    } catch (e) {
      AppLogger.debug('Remembered picture URLs unreadable: $e');
    }
  }

  void _scheduleSave() {
    if (_prefs == null || _uid == null) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _save);
  }

  void _save() {
    final prefs = _prefs;
    final uid = _uid;
    _saveTimer?.cancel();
    _saveTimer = null;
    if (prefs == null || uid == null) return;
    final hits = {
      for (final e in _entries.entries)
        if (e.value.url != null) e.key: e.value.url!,
    };
    final kept = hits.entries.toList();
    if (kept.length > _maxRemembered) {
      kept.removeRange(0, kept.length - _maxRemembered);
    }
    unawaited(
      prefs
          .setString(uid, _prefsName, jsonEncode(Map.fromEntries(kept)))
          .catchError((Object e) {
            AppLogger.debug('Could not remember picture URLs: $e');
          }),
    );
  }

  /// Forget [uid]'s pictures of [kind] (all kinds when null), after an
  /// upload or delete. Other kinds stay cached so they do not flicker.
  void invalidate(String uid, {ProfileImageKind? kind}) {
    final prefix = kind == null ? '$uid/' : '$uid/${kind.name}/';
    _entries.removeWhere((key, entry) {
      if (!key.startsWith(prefix)) return false;
      // The file may keep its URL: the old picture must not come back
      // from the photo cache.
      if (entry.url != null) unawaited(_evict(entry.url!));
      return true;
    });
    notifyListeners();
    _scheduleSave();
  }

  int _generation = 0;

  void _reset() {
    _generation++;
    _entries.clear();
    _inFlight.clear();
    notifyListeners();
  }

  // Both ends of a session start from an empty cache, so nothing looked up
  // for (or during the sign-out of) one account is shown to the next.
  @override
  void attach(String uid) {
    _reset();
    _uid = uid;
    unawaited(_restore(uid));
  }

  @override
  void detach() {
    if (_saveTimer != null) _save();
    _uid = null;
    _reset();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}
}

class _Entry {
  _Entry(
    this.url,
    this.fetchedAt, {
    this.failed = false,
    this.remembered = false,
  });

  final String? url;
  final DateTime fetchedAt;

  /// From an earlier session on this phone: shown at once, looked up again.
  final bool remembered;

  /// The lookup threw (offline, not authorised) rather than finding
  /// nothing: retried much sooner than a real "no picture".
  final bool failed;

  static const _failureTtl = Duration(seconds: 30);

  bool get resolved => true;

  /// Hits are kept for the session; misses are retried after [ttl],
  /// failures after 30 seconds.
  bool isExpired(Duration ttl) =>
      url == null &&
      DateTime.now().difference(fetchedAt) > (failed ? _failureTtl : ttl);
}

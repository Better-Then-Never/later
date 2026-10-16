import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';

/// Names and usernames of other users, looked up once and shared by every
/// list, row and profile header.
///
/// Replaces UserDataService.getUserData: lookups requested in the same
/// microtask are batched into one `whereIn` query (no N+1 reads, BUG-073),
/// missing users stay null instead of becoming "Unknown"/"unknown" strings,
/// and the signed-in user's own profile stays live.
class UserDirectory extends ChangeNotifier implements SessionScoped {
  UserDirectory(this._users, {this.retryAfter = const Duration(seconds: 30)});

  final UserRepository _users;

  /// How long a failed lookup is not retried (avoids rebuild/retry loops).
  final Duration retryAfter;

  final Map<String, UserProfile?> _profiles = {};
  final Map<String, Future<void>> _pending = {};
  final Map<String, DateTime> _failedAt = {};
  final Set<String> _queued = {};
  Completer<void>? _batch;
  int _generation = 0;
  StreamSubscription<UserProfile?>? _ownSub;

  /// The cached profile, or null while unknown or missing. Starts a lookup
  /// the first time a uid is asked for; listeners are notified when it
  /// lands.
  UserProfile? profile(String uid) {
    if (uid.isEmpty) return null;
    if (!_profiles.containsKey(uid)) unawaited(_request([uid]));
    return _profiles[uid];
  }

  /// Whether a lookup for [uid] finished (the user may still be missing).
  bool isResolved(String uid) => _profiles.containsKey(uid);

  /// Loads every uid not cached yet and returns the profiles that exist.
  Future<Map<String, UserProfile>> resolveAll(Iterable<String> uids) async {
    final wanted = uids.where((u) => u.isNotEmpty).toSet();
    await _request(wanted, force: true);
    return {
      for (final uid in wanted)
        if (_profiles[uid] != null) uid: _profiles[uid]!,
    };
  }

  /// Adds profiles that were loaded elsewhere (e.g. search results).
  void prime(Iterable<UserProfile> profiles) {
    var changed = false;
    for (final p in profiles) {
      if (_profiles[p.uid] != p) {
        _profiles[p.uid] = p;
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> _request(Iterable<String> uids, {bool force = false}) {
    final waits = <Future<void>>[];
    final now = DateTime.now();
    for (final uid in uids) {
      if (_profiles.containsKey(uid)) continue;
      final pending = _pending[uid];
      if (pending != null) {
        waits.add(pending);
        continue;
      }
      final failed = _failedAt[uid];
      if (!force && failed != null && now.difference(failed) < retryAfter) {
        continue;
      }
      if (_batch == null) {
        _batch = Completer<void>();
        scheduleMicrotask(_flush);
      }
      _queued.add(uid);
      waits.add(_pending[uid] = _batch!.future);
    }
    return Future.wait(waits);
  }

  Future<void> _flush() async {
    final batch = _batch;
    if (batch == null) return; // Already flushed, or cleared by detach().
    final uids = _queued.toList();
    final generation = _generation;
    _queued.clear();
    _batch = null;
    try {
      final found = await _users.getProfiles(uids);
      if (generation != _generation) return;
      for (final uid in uids) {
        _profiles[uid] = found[uid];
        _failedAt.remove(uid);
      }
    } catch (e, st) {
      AppLogger.warning('Profile lookup failed', error: e, stackTrace: st);
      final now = DateTime.now();
      for (final uid in uids) {
        _failedAt[uid] = now;
      }
    } finally {
      if (generation == _generation) {
        uids.forEach(_pending.remove);
        notifyListeners();
      }
      batch.complete();
    }
  }

  @override
  void attach(String uid) {
    _ownSub = _users.watchProfile(uid).listen(
      (profile) {
        if (profile != null) prime([profile]);
      },
      onError: (Object e, StackTrace st) => AppLogger.warning(
        'Own profile stream failed',
        error: e,
        stackTrace: st,
      ),
    );
  }

  @override
  void detach() {
    unawaited(_ownSub?.cancel());
    _ownSub = null;
    _generation++;
    _profiles.clear();
    _pending.clear();
    _failedAt.clear();
    _queued.clear();
    _batch?.complete();
    _batch = null;
    notifyListeners();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}
}

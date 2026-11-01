import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/session/session_scoped.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/geo_position.dart';
import '../../../data/repositories/repositories.dart';

/// Locked capsules for the signed-in user (capsule v3 B3): whether one may
/// be opened now, and its photo and words, kept apart on the server until
/// then (`capsules/{id}/sealed/content`).
///
/// A capsule may be opened once its date has come and, for a place capsule,
/// once the user opened it at its spot ([unlockHere]); the server lists
/// those in `users/{uid}/unlocked`. Its owner and co-authors could read the
/// sealed part earlier, but the app keeps it locked for them too.
class CapsuleLocks extends ChangeNotifier implements SessionScoped {
  CapsuleLocks(this._capsules, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final CapsuleRepository _capsules;
  final DateTime Function() _clock;

  /// How long a failed read waits before it is tried again.
  static const retryAfter = Duration(seconds: 30);

  String? _uid;
  StreamSubscription<Set<String>>? _unlockedSub;
  Set<String> _unlocked = const {};
  final Map<String, CapsuleContent?> _content = {};
  final Map<String, Future<CapsuleContent?>> _loading = {};
  final Map<String, DateTime> _failedAt = {};

  /// Where [context] has them; null in tests and pages built without them.
  static CapsuleLocks? maybeOf(BuildContext context, {bool listen = true}) {
    try {
      return Provider.of<CapsuleLocks>(context, listen: listen);
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// [capsule] as the screen at [context] should show it ([resolve]), or as
  /// it is where there are no locks.
  static Capsule shown(BuildContext context, Capsule capsule, DateTime now) =>
      maybeOf(context)?.resolve(capsule, now) ?? capsule;

  /// Whether the capsule at [context] may be opened at [now] ([mayOpen]);
  /// by its date alone where there are no locks.
  static bool openAt(BuildContext context, Capsule capsule, DateTime now) =>
      maybeOf(context)?.mayOpen(capsule, now) ?? capsule.isOpen(now);

  /// Whether the user opened place capsule [capsuleId] at its spot.
  bool isUnlocked(String capsuleId) => _unlocked.contains(capsuleId);

  /// Its date has come and, for a place capsule, it was opened there.
  bool mayOpen(Capsule capsule, DateTime now) =>
      capsule.isOpen(now) && (!capsule.opensHere || isUnlocked(capsule.id));

  /// A place capsule whose date has come but which waits to be opened at
  /// its spot ("Ready to open").
  bool waitsHere(Capsule capsule, DateTime now) =>
      capsule.opensHere && capsule.isOpen(now) && !isUnlocked(capsule.id);

  /// [capsule] with its photo and words when it may open and they are
  /// here; otherwise as it is (their read starts, and listeners hear when
  /// it is done).
  Capsule resolve(Capsule capsule, DateTime now) {
    if (!capsule.sealed || capsule.imageUrl != null) return capsule;
    if (!mayOpen(capsule, now)) return capsule;
    if (_content.containsKey(capsule.id)) {
      final content = _content[capsule.id];
      return content == null ? capsule : capsule.withContent(content);
    }
    unawaited(_load(capsule.id).catchError((Object _) => null));
    return capsule;
  }

  /// [capsule] with its photo and words, read now if need be (when it may
  /// open; as it is otherwise, or when they cannot be read).
  Future<Capsule> fill(Capsule capsule) async {
    final now = _clock();
    if (!capsule.sealed || capsule.imageUrl != null) return capsule;
    if (!mayOpen(capsule, now)) return capsule;
    try {
      final content = _content.containsKey(capsule.id)
          ? _content[capsule.id]
          : await _load(capsule.id, force: true);
      return content == null ? capsule : capsule.withContent(content);
    } catch (_) {
      return capsule;
    }
  }

  Future<CapsuleContent?> _load(String id, {bool force = false}) {
    final running = _loading[id];
    if (running != null) return running;
    final failed = _failedAt[id];
    if (!force && failed != null && _clock().difference(failed) < retryAfter) {
      return Future.value();
    }
    final uid = _uid;
    final load = _capsules
        .sealedContent(id)
        .then((content) {
          if (_uid != uid) return content;
          _content[id] = content;
          _failedAt.remove(id);
          notifyListeners();
          return content;
        })
        .catchError((Object e) {
          _failedAt[id] = _clock();
          AppLogger.warning('Sealed capsule $id not read', error: e);
          throw e;
        })
        // A block body: returning the removed future would wait on itself.
        .whenComplete(() {
          _loading.remove(id);
        });
    _loading[id] = load;
    return load;
  }

  /// Opens place capsule [capsule] for the user standing at [at] (a fix
  /// [accuracy] metres good): returns it with its photo and words. Throws
  /// [CapsuleUnlockException] when the server says no.
  Future<Capsule> unlockHere(
    Capsule capsule,
    GeoPosition at, {
    double accuracy = 0,
  }) async {
    final content = await _capsules.unlockHere(
      capsule.id,
      at,
      accuracy: accuracy,
    );
    _unlocked = {..._unlocked, capsule.id};
    _content[capsule.id] = content;
    notifyListeners();
    return content == null ? capsule : capsule.withContent(content);
  }

  @override
  void attach(String uid) {
    _uid = uid;
    _unlockedSub = _capsules
        .watchUnlocked(uid)
        .listen(
          (ids) {
            if (_uid != uid) return;
            _unlocked = ids;
            notifyListeners();
          },
          onError: (Object e) {
            AppLogger.warning('Opened place capsules not read', error: e);
          },
        );
  }

  @override
  void detach() {
    _uid = null;
    unawaited(_unlockedSub?.cancel());
    _unlockedSub = null;
    _unlocked = const {};
    _content.clear();
    _loading.clear();
    _failedAt.clear();
    notifyListeners();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}
}

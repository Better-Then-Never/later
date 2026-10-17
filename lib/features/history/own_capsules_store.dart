import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/models/capsule.dart';
import '../../data/repositories/repositories.dart';
import '../capsules/outbox/capsule_outbox.dart';

/// The signed-in user's own capsules, live and newest first (BUG-063).
///
/// Replaces CapsuleDataService: typed [Capsule]s instead of raw maps (no
/// force unwraps on missing fields, BUG-060) and deletion through the
/// repository, which also removes the images from Storage (BUG-062).
class OwnCapsulesStore extends ChangeNotifier implements SessionScoped {
  OwnCapsulesStore(this._repo, {CapsuleOutbox? outbox}) : _outbox = outbox {
    _outbox?.addListener(_onOutbox);
  }

  final CapsuleRepository _repo;

  /// Capsules waiting for a connection show first, marked pending (F-26).
  final CapsuleOutbox? _outbox;
  List<Capsule> _merged = const [];

  void _onOutbox() {
    _merge();
    notifyListeners();
  }

  void _merge() {
    final server = _capsules;
    final serverIds = {for (final c in server) c.id};
    final own = [
      for (final p in _outbox?.pending ?? const <PendingCapsule>[])
        if (!serverIds.contains(p.id)) p.toCapsule(),
      ...server,
    ];
    // Capsules made with friends join the user's own, newest first.
    _merged = _coAuthored.isEmpty
        ? own
        : ([...own, ..._coAuthored.where((c) => !serverIds.contains(c.id))]
            ..sort(
              (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
                a.createdAt ?? DateTime.now(),
              ),
            ));
  }

  StreamSubscription<List<Capsule>>? _coSub;
  List<Capsule> _coAuthored = const [];
  String? _uid;

  /// [id] is someone else's capsule the user co-authored.
  bool isCoAuthored(String id) => _coAuthored.any((c) => c.id == id);

  StreamSubscription<List<Capsule>>? _sub;
  List<Capsule> _capsules = const [];
  bool _loaded = false;
  AppFailure? _error;

  List<Capsule> get capsules => _merged;

  /// Waiting capsules wait for Wi-Fi (Settings: upload on Wi-Fi only).
  bool get waitingForWifi => _outbox?.waitingForWifi ?? false;
  bool get isLoaded => _loaded;
  AppFailure? get error => _error;

  @override
  void attach(String uid) {
    _uid = uid;
    _coSub = _repo.watchCoAuthored(uid).listen(
      (list) {
        _coAuthored = list;
        _merge();
        notifyListeners();
      },
      onError: (Object e, StackTrace st) => AppLogger.warning(
        'Co-authored capsules stream failed',
        error: e,
        stackTrace: st,
      ),
    );
    _sub = _repo
        .watchOwn(uid)
        .listen(
          (list) {
            _capsules = list;
            _merge();
            _loaded = true;
            _error = null;
            notifyListeners();
          },
          onError: (Object e, StackTrace st) {
            AppLogger.warning(
              'Own capsules stream failed',
              error: e,
              stackTrace: st,
            );
            _error = AppFailure.from(e);
            _loaded = true;
            notifyListeners();
          },
        );
  }

  @override
  void detach() {
    unawaited(_sub?.cancel());
    _sub = null;
    unawaited(_coSub?.cancel());
    _coSub = null;
    _coAuthored = const [];
    _uid = null;
    _capsules = const [];
    _merged = const [];
    _loaded = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _outbox?.removeListener(_onOutbox);
    super.dispose();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}

  /// Takes the user off capsule [id] as a co-author. Returns null on
  /// success; the live list drops it once Firestore confirms.
  Future<AppFailure?> leave(String id) async {
    final uid = _uid;
    if (uid == null) return null;
    try {
      await _repo.leaveCoAuthors(id, uid);
      return null;
    } catch (e, st) {
      AppLogger.error('Leaving a capsule failed', error: e, stackTrace: st);
      return AppFailure.from(e);
    }
  }

  /// Deletes the capsules with [ids] (documents and images). Returns null on
  /// success; the live list drops them once Firestore confirms.
  Future<AppFailure?> delete(Iterable<String> ids) async {
    final wanted = ids.toSet();
    // Waiting ones are only on this phone.
    for (final p in [...?_outbox?.pending]) {
      if (wanted.remove(p.id)) await _outbox!.discard(p.id);
    }
    final targets = _capsules.where((c) => wanted.contains(c.id)).toList();
    // Someone else's capsule: deleting it from the list means leaving it.
    final left = [
      for (final c in _coAuthored)
        if (wanted.contains(c.id)) c.id,
    ];
    if (targets.isEmpty && left.isEmpty) return null;
    try {
      if (targets.isNotEmpty) await _repo.delete(targets);
      if (_uid case final uid? when left.isNotEmpty) {
        await Future.wait(left.map((id) => _repo.leaveCoAuthors(id, uid)));
      }
      return null;
    } catch (e, st) {
      AppLogger.error('Deleting capsules failed', error: e, stackTrace: st);
      return AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.historyErrorDelete,
      );
    }
  }
}

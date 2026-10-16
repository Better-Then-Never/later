import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/models/capsule.dart';
import '../../data/repositories/repositories.dart';

/// The signed-in user's own capsules, live and newest first (BUG-063).
///
/// Replaces CapsuleDataService: typed [Capsule]s instead of raw maps (no
/// force unwraps on missing fields, BUG-060) and deletion through the
/// repository, which also removes the images from Storage (BUG-062).
class OwnCapsulesStore extends ChangeNotifier implements SessionScoped {
  OwnCapsulesStore(this._repo);

  final CapsuleRepository _repo;

  StreamSubscription<List<Capsule>>? _sub;
  List<Capsule> _capsules = const [];
  bool _loaded = false;
  AppFailure? _error;

  List<Capsule> get capsules => _capsules;
  bool get isLoaded => _loaded;
  AppFailure? get error => _error;

  @override
  void attach(String uid) {
    _sub = _repo
        .watchOwn(uid)
        .listen(
          (list) {
            _capsules = list;
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
    _capsules = const [];
    _loaded = false;
    _error = null;
    notifyListeners();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}

  /// Deletes the capsules with [ids] (documents and images). Returns null on
  /// success; the live list drops them once Firestore confirms.
  Future<AppFailure?> delete(Iterable<String> ids) async {
    final wanted = ids.toSet();
    final targets = _capsules.where((c) => wanted.contains(c.id)).toList();
    if (targets.isEmpty) return null;
    try {
      await _repo.delete(targets);
      return null;
    } catch (e, st) {
      AppLogger.error('Deleting capsules failed', error: e, stackTrace: st);
      return AppFailure.from(e, fallbackMessage: 'Could not delete capsules');
    }
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/logging/app_logger.dart';
import '../../core/session/session_scoped.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/repositories.dart';

/// The signed-in user's in-app notifications, live from Firestore.
///
/// Replaces the one-shot load at cold start (BUG-020): the list follows the
/// session and updates in real time, and every action addresses
/// notifications by id, never by list position (BUG-030).
class NotificationsStore extends ChangeNotifier implements SessionScoped {
  NotificationsStore(this._repo, {this.limit = 100});

  final NotificationRepository _repo;
  final int limit;

  StreamSubscription<List<AppNotification>>? _sub;
  String? _uid;
  List<AppNotification> _items = const [];
  bool _loaded = false;
  AppFailure? _error;

  List<AppNotification> get notifications => _items;
  bool get isLoaded => _loaded;
  AppFailure? get error => _error;
  int get unreadCount => _items.where((n) => !n.isRead).length;

  @override
  void attach(String uid) {
    _uid = uid;
    _subscribe(uid);
  }

  /// Completes with the first result of the current subscription.
  Completer<void>? _firstResult;

  void _subscribe(String uid) {
    _firstResult = Completer<void>();
    _sub = _repo
        .watch(uid, limit: limit)
        .listen(
          (items) {
            _items = items;
            _loaded = true;
            _error = null;
            notifyListeners();
            _settle();
          },
          onError: (Object e, StackTrace st) {
            AppLogger.warning(
              'Notifications stream failed',
              error: e,
              stackTrace: st,
            );
            _error = AppFailure.from(e);
            _loaded = true;
            notifyListeners();
            _settle();
          },
        );
  }

  void _settle() {
    final first = _firstResult;
    if (first != null && !first.isCompleted) first.complete();
  }

  /// Pull to refresh: listens again from scratch (a fresh read, and a way
  /// out of a stream that failed) and completes with its first result, or
  /// after 10 s.
  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;
    await _sub?.cancel();
    _subscribe(uid);
    await _firstResult!.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {},
    );
  }

  @override
  void detach() {
    unawaited(_sub?.cancel());
    _sub = null;
    _uid = null;
    _items = const [];
    _loaded = false;
    _error = null;
    notifyListeners();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}

  Future<void> markRead(Iterable<String> ids) async {
    final uid = _uid;
    final unread = ids.toSet().intersection({
      for (final n in _items)
        if (!n.isRead) n.id,
    });
    if (uid == null || unread.isEmpty) return;
    // Optimistic: the listener confirms (or reverts) shortly after.
    _items = [
      for (final n in _items) unread.contains(n.id) ? n.markedRead() : n,
    ];
    notifyListeners();
    await _repo.markRead(uid, unread);
  }

  Future<void> delete(Iterable<String> ids) async {
    final uid = _uid;
    final toDelete = ids.toSet();
    if (uid == null || toDelete.isEmpty) return;
    _items = [
      for (final n in _items)
        if (!toDelete.contains(n.id)) n,
    ];
    notifyListeners();
    await _repo.delete(uid, toDelete);
  }
}

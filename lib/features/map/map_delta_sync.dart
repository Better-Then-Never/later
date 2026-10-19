import 'dart:async';
import 'dart:math' as math;

import '../../core/logging/app_logger.dart';
import '../../data/models/capsule.dart';
import '../../data/repositories/repositories.dart';
import 'map_pin_store.dart';

/// The map's friends' and public capsules from what the phone kept and what
/// changed since (docs/map/COLD_START.md, "Delta sync"), instead of reading
/// all of them at every start (1,114 for the test account; Firestore counts
/// each one once a listener has been away for half an hour). Capsules are
/// never edited, so a change is a new capsule or a deleted one
/// (functions/lib/mapsync.js); the own and co-authored lists stay full
/// listeners (the history page listens to the own one anyway).
///
/// Any doubt, and the map reads everything again ([onFailed]): an error
/// (the backend not deployed yet: a missing index or rule), a query that
/// hit its limit, a friend added or removed during the session.
class MapDeltaSync {
  MapDeltaSync({
    required CapsuleRepository capsules,
    required StoredMap stored,
    required List<String> friendIds,
    required this.onChanged,
    required this.onFailed,
    this.limit = 500,
  }) : _capsules = capsules,
       _since = stored.syncedTo!,
       _friendIds = List.of(friendIds),
       _syncedTo = stored.syncedTo!,
       _keptFriends = [
         for (final p in stored.pins)
           if (p.source == PinSource.friends) p.capsule,
       ],
       _keptPublic = [
         for (final p in stored.pins)
           if (p.source == PinSource.public) p.capsule,
       ],
       _keptFriendIds = stored.friendIds.toSet();

  final CapsuleRepository _capsules;
  final DateTime _since;
  final List<String> _friendIds;
  final Set<String> _keptFriendIds;
  final List<Capsule> _keptFriends;
  final List<Capsule> _keptPublic;

  /// Most a query may return before its answer is doubted (more may exist).
  final int limit;

  /// Something changed: [friends], [public] or the answers.
  final void Function() onChanged;

  /// The sync cannot be trusted: read everything ([reason] for the log).
  final void Function(String reason) onFailed;

  var _newFriends = const <Capsule>[];
  var _addedFriends = const <Capsule>[];
  var _newPublic = const <Capsule>[];
  final _deleted = <String>{};
  DateTime _syncedTo;
  bool _friendsAnswered = false;
  bool _addedAnswered = false;
  bool _publicAnswered = false;
  bool _failed = false;
  final _subs = <StreamSubscription<Object?>>[];

  /// Friends added since the phone kept the map: their older capsules are
  /// read in full.
  List<String> get _added => [
    for (final id in _friendIds)
      if (!_keptFriendIds.contains(id)) id,
  ];

  bool get friendsAnswered => _friendsAnswered && _addedAnswered;
  bool get publicAnswered => _publicAnswered;

  /// The newest change seen (server time): where the next start begins.
  DateTime get syncedTo => _syncedTo;

  /// Today's friends' friends-only capsules: those kept (of friends still),
  /// those new since, a new friend's all, none deleted.
  List<Capsule> get friends {
    final friends = _friendIds.toSet();
    final byId = <String, Capsule>{
      for (final c in _keptFriends)
        if (friends.contains(c.ownerId)) c.id: c,
      for (final c in _addedFriends) c.id: c,
      for (final c in _newFriends) c.id: c,
    };
    byId.removeWhere((id, _) => _deleted.contains(id));
    return List.unmodifiable(byId.values);
  }

  /// The public capsules kept and those new since (anywhere), none deleted.
  List<Capsule> get public {
    final byId = <String, Capsule>{
      for (final c in _keptPublic) c.id: c,
      for (final c in _newPublic) c.id: c,
    };
    byId.removeWhere((id, _) => _deleted.contains(id));
    return List.unmodifiable(byId.values);
  }

  void start() {
    final added = _added;
    final known = [
      for (final id in _friendIds)
        if (_keptFriendIds.contains(id)) id,
    ];
    _listen(_capsules.watchFriendsSince(known, _since, limit: limit), (
      List<Capsule> list,
    ) {
      if (_full(list, 'friends')) return;
      _newFriends = list;
      _seen(list);
      _friendsAnswered = true;
    });
    if (added.isEmpty) {
      _addedAnswered = true;
    } else {
      _listen(_capsules.watchFriends(added), (List<Capsule> list) {
        _addedFriends = list;
        _seen(list);
        _addedAnswered = true;
      });
    }
    _listen(_capsules.watchPublicSince(_since, limit: limit), (
      List<Capsule> list,
    ) {
      if (_full(list, 'public')) return;
      _newPublic = list;
      _seen(list);
      _publicAnswered = true;
    });
    _listen(_capsules.watchDeletionsSince(_friendIds, _since, limit: limit), (
      List<CapsuleDeletion> list,
    ) {
      if (list.length >= limit) {
        _fail('deletions at their limit');
        return;
      }
      for (final d in list) {
        _deleted.add(d.id);
        _syncedTo = _later(_syncedTo, d.deletedAt);
      }
    });
  }

  void _listen<T>(Stream<T> stream, void Function(T) onData) {
    _subs.add(
      stream.listen((value) {
        if (_failed) return;
        onData(value);
        if (!_failed) onChanged();
      }, onError: (Object e) => _fail('$e')),
    );
  }

  bool _full(List<Capsule> list, String what) {
    if (list.length < limit) return false;
    _fail('$what at their limit');
    return true;
  }

  void _seen(Iterable<Capsule> list) {
    for (final c in list) {
      if (c.createdAt case final at?) _syncedTo = _later(_syncedTo, at);
    }
  }

  static DateTime _later(DateTime a, DateTime b) =>
      DateTime.fromMillisecondsSinceEpoch(
        math.max(a.millisecondsSinceEpoch, b.millisecondsSinceEpoch),
      );

  void _fail(String reason) {
    if (_failed) return;
    _failed = true;
    AppLogger.warning('Map sync off, reading everything: $reason');
    dispose();
    onFailed(reason);
  }

  void dispose() {
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';
import '../users/user_directory.dart';
import 'friends_store.dart';

/// "Make friends" suggestions on the Add Friends page.
///
/// Replaces an unbounded realtime listener on the whole `users` collection
/// that was re-created on every rebuild (BUG-071): one bounded prefix query
/// per (debounced) search, on the lower-cased username (BUG-072), with an
/// error state instead of a silently empty list. Results are primed into
/// the [UserDirectory] so rows need no extra reads (BUG-073).
///
/// Without a query it suggests friends of the user's friends, most mutual
/// friends first (F-57: it used to list the first users of the whole app).
/// A query finds people by username and by name (those who allow it), the
/// username matches first; never the user themselves or someone blocked.
class FriendSuggestionsController extends ChangeNotifier {
  FriendSuggestionsController({
    required UserRepository users,
    required UserDirectory directory,
    FriendsStore? friends,
    this.limit = 50,
    this.suggestionLimit = 20,
    this.debounce = const Duration(milliseconds: 300),
  }) : _users = users,
       _directory = directory,
       _friends = friends {
    unawaited(_load());
  }

  final UserRepository _users;
  final UserDirectory _directory;
  final FriendsStore? _friends;
  final int suggestionLimit;
  Map<String, int> _mutual = const {};

  /// Friends in common with a suggested user (0 for search results).
  int mutualCount(String uid) => _mutual[uid] ?? 0;

  /// No query: the list shows friends of friends.
  bool get isSuggesting => _query.isEmpty;
  final int limit;
  final Duration debounce;

  Timer? _timer;
  String _query = '';
  int _request = 0;
  bool _disposed = false;

  List<UserProfile> _results = const [];
  bool _loading = true;
  AppFailure? _error;

  List<UserProfile> get results => _results;
  bool get isLoading => _loading;
  AppFailure? get error => _error;
  String get query => _query;

  /// "@Dave " -> "dave" (names are searched in lower case too).
  static String normalize(String input) {
    var q = input.trim().toLowerCase();
    if (q.startsWith('@')) q = q.substring(1);
    return q;
  }

  void search(String input) {
    final next = normalize(input);
    if (next == _query) return;
    _query = next;
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(_load()));
  }

  Future<void> retry() => _load();

  Future<void> _load() async {
    final request = ++_request;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (_query.isEmpty) {
        final found = await _friendsOfFriends();
        if (_disposed || request != _request) return;
        _results = found;
      } else {
        final (byUsername, byName) = await (
          _users.searchByUsername(_query, limit: limit),
          _users.searchByName(_query, limit: limit),
        ).wait;
        if (_disposed || request != _request) return;
        final me = _friends?.uid;
        final blocked = _friends?.blocked ?? const <String>{};
        final seen = <String>{};
        final found = [
          for (final p in [...byUsername, ...byName])
            if (p.uid != me && !blocked.contains(p.uid) && seen.add(p.uid)) p,
        ].take(limit).toList();
        _directory.prime(found);
        _mutual = const {};
        _results = found;
      }
    } catch (e, st) {
      if (_disposed || request != _request) return;
      AppLogger.warning('User search failed', error: e, stackTrace: st);
      _results = const [];
      _error = AppFailure.from(
        e,
        fallbackMessage: AppL10n.current.friendsErrorLoadUsers,
      );
    }
    _loading = false;
    notifyListeners();
  }

  /// People two steps away, ranked by friends in common; at most two reads
  /// of up to 30 profiles each (the friends, then the candidates), most of
  /// them already in the directory.
  Future<List<UserProfile>> _friendsOfFriends() async {
    final store = _friends;
    final me = store?.uid;
    if (store == null || me == null) return const [];
    final mine = store.friendIds;
    if (mine.isEmpty) return const [];
    final friends = await _directory.resolveAll(mine.take(30));
    final counts = <String, int>{};
    for (final friend in friends.values) {
      for (final other in friend.friends) {
        if (other == me || mine.contains(other)) continue;
        if (store.blocked.contains(other)) continue;
        counts[other] = (counts[other] ?? 0) + 1;
      }
    }
    final ranked = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    final top = ranked.take(suggestionLimit).map((e) => e.key).toList();
    final profiles = await _directory.resolveAll(top);
    _mutual = {for (final uid in top) uid: counts[uid]!};
    return [
      for (final uid in top)
        if (profiles[uid] case final UserProfile p) p,
    ];
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

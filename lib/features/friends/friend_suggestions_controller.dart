import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';
import '../users/user_directory.dart';

/// "Make friends" suggestions on the Add Friends page.
///
/// Replaces an unbounded realtime listener on the whole `users` collection
/// that was re-created on every rebuild (BUG-071): one bounded prefix query
/// per (debounced) search, on the lower-cased username (BUG-072), with an
/// error state instead of a silently empty list. Results are primed into
/// the [UserDirectory] so rows need no extra reads (BUG-073).
class FriendSuggestionsController extends ChangeNotifier {
  FriendSuggestionsController({
    required UserRepository users,
    required UserDirectory directory,
    this.limit = 50,
    this.debounce = const Duration(milliseconds: 300),
  }) : _users = users,
       _directory = directory {
    unawaited(_load());
  }

  final UserRepository _users;
  final UserDirectory _directory;
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

  /// "@Dave " -> "dave".
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
      final found = await _users.searchByUsername(_query, limit: limit);
      if (_disposed || request != _request) return;
      _directory.prime(found);
      _results = found;
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

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}

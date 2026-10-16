import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/services/preferences_store.dart';
import 'friends_store.dart';

/// The up-to-three friends shown on the profile page: the pinned ones
/// first, then random other friends.
///
/// Fixes BUG-078 (the row reshuffled and re-fetched images on every
/// rebuild: the random fill is now chosen once per friend list) and BUG-079
/// (stale pins of former friends no longer use up the three slots). Pins
/// are stored per user (PreferencesStore), never under a global key.
class PinnedFriendsController extends ChangeNotifier {
  PinnedFriendsController({
    required FriendsStore friends,
    required PreferencesStore prefs,
    Random? random,
  }) : _friends = friends,
       _prefs = prefs,
       _random = random ?? Random() {
    _friends.addListener(_onFriendsChanged);
    unawaited(_loadPins());
  }

  static const maxPinned = 3;

  final FriendsStore _friends;
  final PreferencesStore _prefs;
  final Random _random;

  List<String> _pins = const [];
  bool _pinsLoaded = false;
  Set<String> _friendIds = const {};
  List<String> _display = const [];
  bool _disposed = false;

  bool get isLoading => !_pinsLoaded || !_friends.isLoaded;
  Set<String> get allFriends => _friends.friendIds;

  /// Pins that are still friends, in the order they were chosen.
  List<String> get pinnedUids =>
      _pins.where(_friends.friendIds.contains).toList();

  /// What the profile row shows; stable until friends or pins change.
  List<String> get displayFriends => _display;

  Future<void> _loadPins() async {
    final uid = _friends.uid;
    if (uid == null) return;
    final pins = await _prefs.pinnedFriends(uid);
    if (_disposed) return;
    _pins = pins;
    _pinsLoaded = true;
    _recompute(reshuffle: true);
  }

  void _onFriendsChanged() {
    if (setEquals(_friends.friendIds, _friendIds)) {
      notifyListeners(); // isLoading may have changed.
      return;
    }
    _recompute(reshuffle: true);
  }

  void _recompute({required bool reshuffle}) {
    _friendIds = _friends.friendIds;
    final pinned = pinnedUids.take(maxPinned).toList();
    final others = _friendIds.difference(pinned.toSet()).toList()..sort();
    if (reshuffle) others.shuffle(_random);
    _display = [...pinned, ...others.take(maxPinned - pinned.length)];
    notifyListeners();
  }

  Future<void> setPinnedFriends(List<String> uids) async {
    final uid = _friends.uid;
    if (uid == null) return;
    _pins = uids.where(_friends.friendIds.contains).take(maxPinned).toList();
    _recompute(reshuffle: true);
    await _prefs.setPinnedFriends(uid, _pins);
  }

  @override
  void dispose() {
    _disposed = true;
    _friends.removeListener(_onFriendsChanged);
    super.dispose();
  }
}

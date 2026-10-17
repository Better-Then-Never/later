import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_failure.dart';
import '../../data/models/user_settings.dart';
import '../../data/services/preferences_store.dart';
import '../messages/chats_store.dart';
import '../settings/settings_store.dart';
import 'friends_store.dart';

/// The friends at the top of the profile: the pinned ones first (kept in the
/// settings document, so on every phone), then the ones the user chatted
/// with most recently, then the rest in a stable order.
///
/// Fixes BUG-078 (no reshuffle on rebuilds: nothing is random any more) and
/// BUG-079 (pins of former friends never use up a place). Pins this phone
/// kept before they were synced move to the account once.
class PinnedFriendsController extends ChangeNotifier {
  PinnedFriendsController({
    required FriendsStore friends,
    required SettingsStore settings,
    ChatsStore? chats,
    PreferencesStore? prefs,
  }) : _friends = friends,
       _settings = settings,
       _chats = chats,
       _prefs = prefs {
    _friends.addListener(_recompute);
    _settings.addListener(_recompute);
    _chats?.addListener(_recompute);
    _recompute();
  }

  static const maxPinned = UserSettings.maxPinnedFriends;

  /// Friends shown in the profile's row.
  static const maxShown = 5;

  final FriendsStore _friends;
  final SettingsStore _settings;
  final ChatsStore? _chats;
  final PreferencesStore? _prefs;

  List<String> _display = const [];
  bool _migrationChecked = false;

  bool get isLoading => !_friends.isLoaded || !_settings.isLoaded;
  Set<String> get allFriends => _friends.friendIds;

  /// Pins that are still friends, in the order they were chosen.
  List<String> get pinnedUids =>
      _settings.pinnedFriends.where(_friends.friendIds.contains).toList();

  bool isPinned(String uid) => pinnedUids.contains(uid);

  /// What the profile row shows; stable until friends, pins or chats change.
  List<String> get displayFriends => _display;

  /// Friends by their latest two-person chat, newest first.
  List<String> _recent() {
    final me = _friends.uid;
    final chats = _chats;
    if (me == null || chats == null) return const [];
    final dated = [
      for (final c in chats.chats)
        if (!c.isGroup && c.lastUpdated != null) c,
    ]..sort((a, b) => b.lastUpdated!.compareTo(a.lastUpdated!));
    return [
      for (final c in dated)
        for (final other in c.othersThan(me))
          if (_friends.friendIds.contains(other)) other,
    ];
  }

  void _recompute() {
    if (!isLoading) unawaited(_migrateLocalPins());
    final pinned = pinnedUids.take(maxPinned).toList();
    final shown = <String>{...pinned, ..._recent()};
    final rest = _friends.friendIds.difference(shown).toList()..sort();
    final next = [...shown, ...rest].take(maxShown).toList();
    if (listEquals(next, _display)) {
      notifyListeners(); // isLoading may have changed.
      return;
    }
    _display = next;
    notifyListeners();
  }

  /// Pins kept on this phone before they moved to the account.
  Future<void> _migrateLocalPins() async {
    if (_migrationChecked) return;
    _migrationChecked = true;
    final prefs = _prefs;
    final uid = _friends.uid;
    if (prefs == null || uid == null || _settings.pinnedFriends.isNotEmpty) {
      return;
    }
    final local = await prefs.pinnedFriends(uid);
    if (local.isNotEmpty) await setPinnedFriends(local);
  }

  /// Pins [uids] (friends only, at most [maxPinned]), in this order.
  Future<AppFailure?> setPinnedFriends(List<String> uids) => _settings
      .setPinnedFriends(uids.where(_friends.friendIds.contains).toList());

  /// Pins [uid] at the end, or unpins them.
  Future<AppFailure?> togglePin(String uid) => setPinnedFriends(
    isPinned(uid) ? (pinnedUids..remove(uid)) : [...pinnedUids, uid],
  );

  @override
  void dispose() {
    _friends.removeListener(_recompute);
    _settings.removeListener(_recompute);
    _chats?.removeListener(_recompute);
    super.dispose();
  }
}

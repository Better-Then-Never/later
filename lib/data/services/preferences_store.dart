import 'package:shared_preferences/shared_preferences.dart';

/// Device-local preferences, scoped per signed-in user so nothing leaks from
/// one account to the next on a shared device.
class PreferencesStore {
  PreferencesStore({Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefs;

  static String _key(String uid, String name) => 'u:$uid:$name';

  Future<List<String>> pinnedFriends(String uid) async =>
      (await _prefs).getStringList(_key(uid, 'pinned_friend_uids')) ?? const [];

  Future<void> setPinnedFriends(String uid, List<String> uids) async =>
      (await _prefs).setStringList(_key(uid, 'pinned_friend_uids'), uids);

  /// Removes data written by older versions under global keys (profile and
  /// background bytes, pinned friends) that could belong to another account.
  Future<void> purgeLegacyGlobalKeys() async {
    final prefs = await _prefs;
    for (final key in const [
      'profile_image',
      'background_image',
      'pinned_friend_uids',
    ]) {
      await prefs.remove(key);
    }
  }
}

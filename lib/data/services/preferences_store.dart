import 'package:shared_preferences/shared_preferences.dart';

/// Device-local preferences, scoped per signed-in user so nothing leaks from
/// one account to the next on a shared device.
class PreferencesStore {
  PreferencesStore({Future<SharedPreferences>? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance();

  final Future<SharedPreferences> _prefs;
  SharedPreferences? _ready;

  static String _key(String uid, String name) => 'u:$uid:$name';
  static String _deviceKey(String name) => 'device:$name';

  /// Loads the preferences once, before the first frame, so device settings
  /// (theme, language, interface size) can be read synchronously.
  Future<void> init() async => _ready ??= await _prefs;

  /// A setting of this device (not of the account); null before [init].
  String? deviceStringSync(String name) => _ready?.getString(_deviceKey(name));

  /// [value] null removes the setting.
  Future<void> setDeviceString(String name, String? value) async {
    final prefs = await _prefs;
    if (value == null) {
      await prefs.remove(_deviceKey(name));
    } else {
      await prefs.setString(_deviceKey(name), value);
    }
  }

  Future<List<String>> pinnedFriends(String uid) async =>
      (await _prefs).getStringList(_key(uid, 'pinned_friend_uids')) ?? const [];

  Future<void> setPinnedFriends(String uid, List<String> uids) async =>
      (await _prefs).setStringList(_key(uid, 'pinned_friend_uids'), uids);

  Future<String?> string(String uid, String name) async =>
      (await _prefs).getString(_key(uid, name));

  Future<void> setString(String uid, String name, String value) async =>
      (await _prefs).setString(_key(uid, name), value);

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

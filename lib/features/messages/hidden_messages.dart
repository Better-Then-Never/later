import '../../data/services/preferences_store.dart';

/// Messages the user deleted for themselves only: kept on this phone, per
/// account and chat (the others still have them).
class HiddenMessages {
  const HiddenMessages(this._prefs);

  final PreferencesStore _prefs;

  /// The most kept per chat (the oldest go first).
  static const max = 500;

  static String _key(String chatId) => 'hidden_messages_$chatId';

  Future<Set<String>> load(String uid, String chatId) async {
    final saved = await _prefs.string(uid, _key(chatId));
    if (saved == null || saved.isEmpty) return {};
    return saved.split('\n').toSet();
  }

  Future<void> hide(String uid, String chatId, String messageId) async {
    final ids = [...await load(uid, chatId), messageId];
    final kept = ids.length > max ? ids.sublist(ids.length - max) : ids;
    await _prefs.setString(uid, _key(chatId), kept.join('\n'));
  }
}

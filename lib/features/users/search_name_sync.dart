import 'dart:async';

import '../../app/session/session_controller.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../data/repositories/repositories.dart';
import '../settings/settings_store.dart';

/// Keeps the user's entry in the name search (`nameLower`) in step with
/// their name and the "Find me by name" switch: written when it is missing
/// or stale (an older app renamed them, or it never existed), removed when
/// the switch is off. One write per change, never a loop.
class SearchNameSync {
  SearchNameSync({
    required SessionController session,
    required SettingsStore settings,
    required UserRepository users,
  }) : _session = session,
       _settings = settings,
       _users = users;

  final SessionController _session;
  final SettingsStore _settings;
  final UserRepository _users;

  /// The last value written per account, so a slow stream does not repeat it.
  String? _sent;

  void start() {
    _session.addListener(_check);
    _settings.addListener(_check);
    _check();
  }

  void dispose() {
    _session.removeListener(_check);
    _settings.removeListener(_check);
  }

  /// What the rules accept: exactly the name in lower case.
  static String? searchNameFor(String name) =>
      name.trim().isEmpty ? null : name.toLowerCase();

  void _check() {
    final uid = _session.uid;
    final profile = _session.profile;
    if (uid == null || profile == null || profile.uid != uid) return;
    if (!_settings.isLoaded) return;
    // A profile that is still the loading placeholder is never indexed.
    if (profile.username == AppL10n.current.commonUnknownUsername) return;
    final wanted = _settings.privacy.findByName
        ? searchNameFor(profile.name)
        : null;
    if (profile.searchName == wanted) return;
    final key = '$uid:$wanted';
    if (_sent == key) return;
    _sent = key;
    unawaited(
      _users.setSearchName(uid, wanted).catchError((Object e, StackTrace st) {
        AppLogger.warning(
          'Name search entry not saved',
          error: e,
          stackTrace: st,
        );
        if (_sent == key) _sent = null;
      }),
    );
  }
}

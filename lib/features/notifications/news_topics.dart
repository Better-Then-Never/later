import 'dart:async';

import '../../core/config/feature_flags.dart';
import '../../core/logging/app_logger.dart';
import '../../data/services/preferences_store.dart';
import '../../data/services/push_messaging_service.dart';
import '../settings/settings_store.dart';

/// Keeps this device subscribed to the announcements of the Later team in
/// the user's language (`news_<lang>` plus `platform_<os>`, see
/// functions/lib/broadcast.js) while "News from Later" and notifications are
/// on, and unsubscribed otherwise. The topic in use is remembered on the
/// device, so a language change or a switch-off leaves the old topic.
/// Signing out revokes the token, which ends every subscription.
class NewsTopics {
  NewsTopics({
    required TopicSubscriber push,
    required SettingsStore settings,
    required PreferencesStore prefs,
    String? platform,
  }) : _push = push,
       _settings = settings,
       _prefs = prefs,
       _platform = platform ?? PushMessagingService.platformName;

  final TopicSubscriber _push;
  final String _platform;
  final SettingsStore _settings;
  final PreferencesStore _prefs;

  static const _key = 'news_topic';
  bool _syncing = false;
  bool _again = false;

  void start() {
    if (!FeatureFlags.news) return;
    _settings.addListener(_onSettings);
  }

  void dispose() => _settings.removeListener(_onSettings);

  /// The topic this device should be on, or null.
  static String? topicFor({
    required bool enabled,
    required bool news,
    String? language,
  }) => enabled && news ? 'news_${language ?? 'en'}' : null;

  void _onSettings() {
    if (!_settings.isLoaded) {
      // Signed out (the token, and with it every subscription, is gone) or
      // not loaded yet: subscribe again once the settings arrive.
      unawaited(_prefs.setDeviceString(_key, null));
      return;
    }
    unawaited(_sync());
  }

  Future<void> _sync() async {
    // One sync at a time; a change during one runs another after it.
    if (_syncing) {
      _again = true;
      return;
    }
    _syncing = true;
    try {
      do {
        _again = false;
        final n = _settings.notifications;
        final want = topicFor(
          enabled: n.enabled,
          news: n.news,
          language: _settings.settings.language,
        );
        final had = _prefs.deviceStringSync(_key);
        if (want == had) continue;
        final platform = 'platform_$_platform';
        if (had != null) await _push.unsubscribeFromTopic(had);
        if (want != null) {
          await _push.subscribeToTopic(want);
          await _push.subscribeToTopic(platform);
        } else {
          await _push.unsubscribeFromTopic(platform);
        }
        await _prefs.setDeviceString(_key, want);
        AppLogger.debug('News topic: ${had ?? '-'} -> ${want ?? '-'}');
      } while (_again);
    } catch (e) {
      AppLogger.warning('News topic update failed', error: e);
    } finally {
      _syncing = false;
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/user_settings.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/data/services/push_messaging_service.dart';
import 'package:later/features/notifications/news_topics.dart';
import 'package:later/features/settings/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_repositories.dart';

class _Topics implements TopicSubscriber {
  final subscribed = <String>{};
  final calls = <String>[];

  @override
  Future<void> subscribeToTopic(String topic) async {
    calls.add('+$topic');
    subscribed.add(topic);
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    calls.add('-$topic');
    subscribed.remove(topic);
  }
}

void main() {
  late FakeSettingsRepository repo;
  late SettingsStore settings;
  late PreferencesStore prefs;
  late _Topics topics;
  late NewsTopics news;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesStore();
    await prefs.init();
    repo = FakeSettingsRepository();
    settings = SettingsStore(repo, utcOffsetMinutes: () => 0);
    topics = _Topics();
    news = NewsTopics(
      push: topics,
      settings: settings,
      prefs: prefs,
      platform: 'android',
    )..start();
  });

  tearDown(() => news.dispose());

  test(
    'subscribes in the account language, moves with it, leaves when off',
    () async {
      repo.docs['alice'] = const UserSettings(language: 'de');
      settings.attach('alice');
      await pumpEventQueue();
      expect(topics.subscribed, {'news_de', 'platform_android'});

      await repo.saveLanguage('alice', 'pl');
      await pumpEventQueue();
      expect(topics.subscribed, {'news_pl', 'platform_android'});

      await settings.updateNotifications(
        settings.notifications.copyWith(news: false),
      );
      await pumpEventQueue();
      expect(topics.subscribed, isEmpty);
      settings.detach();
    },
  );

  test('turning all notifications off also leaves the news', () {
    expect(
      NewsTopics.topicFor(enabled: false, news: true, language: 'ru'),
      isNull,
    );
    expect(
      NewsTopics.topicFor(enabled: true, news: true, language: null),
      'news_en',
    );
  });
}

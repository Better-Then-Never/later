import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/data/models/user_settings.dart';
import 'package:later/data/services/cache_service.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/settings/device_settings_store.dart';
import 'package:later/features/settings/pages/notification_settings_page.dart';
import 'package:later/features/settings/settings_store.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fakes/fake_repositories.dart';
import '../helpers/test_app.dart';

void main() {
  group('DeviceSettingsStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('remembers choices per user', () async {
      final prefs = PreferencesStore();
      final store = DeviceSettingsStore(prefs)..attach('alice');
      await pumpEventQueue();
      expect(store.mapLook, MapLook.standard);
      expect(store.startCamera, StartCamera.back);

      await store.setMapLook(MapLook.satellite);
      await store.setStartCamera(StartCamera.front);
      store.detach();
      expect(store.mapLook, MapLook.standard);

      store.attach('bob');
      await pumpEventQueue();
      expect(store.mapLook, MapLook.standard, reason: 'another account');
      store.detach();

      store.attach('alice');
      await pumpEventQueue();
      expect(store.mapLook, MapLook.satellite);
      expect(store.startCamera, StartCamera.front);
    });

    test('unknown stored values fall back to the defaults', () {
      expect(MapLook.parse('3d'), MapLook.standard);
      expect(StartCamera.parse(null), StartCamera.back);
    });
  });

  group('CacheService', () {
    test('measures and clears the cache directory', () async {
      final dir = await Directory.systemTemp.createTemp('later_cache_test');
      addTearDown(() async {
        if (dir.existsSync()) await dir.delete(recursive: true);
      });
      await File('${dir.path}/a.jpg').writeAsBytes(List.filled(1000, 1));
      await Directory('${dir.path}/sub').create();
      await File('${dir.path}/sub/b.jpg').writeAsBytes(List.filled(24, 1));

      var downloadsCleared = false;
      final cache = CacheService(
        directory: () async => dir,
        clearDownloads: () async => downloadsCleared = true,
      );
      expect(await cache.size(), greaterThanOrEqualTo(1024));
      await cache.clear();
      expect(dir.listSync(), isEmpty);
      expect(dir.existsSync(), isTrue);
      expect(downloadsCleared, isTrue);
    });

    test('formats sizes', () {
      expect(CacheService.format(0), '0 B');
      expect(CacheService.format(2048), '2 KB');
      expect(CacheService.format(3 * 1024 * 1024 + 400 * 1024), '3.4 MB');
    });

    test('formats sizes in the app language', () {
      addTearDown(() => AppL10n.update(const Locale('en')));
      const size = 3 * 1024 * 1024 + 400 * 1024;
      AppL10n.update(const Locale('ru'));
      expect(CacheService.format(size), '3,4 МБ');
      AppL10n.update(const Locale('de'));
      expect(CacheService.format(size), '3,4 MB');
      expect(CacheService.format(2048), '2 KB');
    });
  });

  group('NotificationSettingsPage', () {
    testWidgets('switches save, and turning everything off disables the rest', (
      tester,
    ) async {
      final repo = FakeSettingsRepository();
      final store = SettingsStore(repo, utcOffsetMinutes: () => 0)
        ..attach('alice');
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsStore>.value(
          value: store,
          child: testApp(home: const NotificationSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();
      expect(repo.docs['alice']!.notifications.messages, isFalse);

      await tester.tap(find.text('Push notifications'));
      await tester.pumpAndSettle();
      expect(repo.docs['alice']!.notifications.enabled, isFalse);
      expect(find.text('You get no pushes from Later'), findsOneWidget);

      // Category switches are disabled now.
      await tester.tap(find.text('New followers'));
      await tester.pumpAndSettle();
      expect(repo.docs['alice']!.notifications.follows, isTrue);

      store.detach();
    });

    testWidgets('nothing can change before the saved settings arrive', (
      tester,
    ) async {
      final repo = _SlowSettingsRepository();
      final store = SettingsStore(repo, utcOffsetMinutes: () => 0)
        ..attach('alice');
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsStore>.value(
          value: store,
          child: testApp(home: const NotificationSettingsPage()),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Push notifications'));
      await tester.tap(find.text('Messages'));
      await tester.pump();
      expect(repo.saves, 0);
      store.detach();
    });

    testWidgets('quiet hours show their times when on', (tester) async {
      final repo = FakeSettingsRepository();
      final store = SettingsStore(repo, utcOffsetMinutes: () => 0)
        ..attach('alice');
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsStore>.value(
          value: store,
          child: testApp(home: const NotificationSettingsPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('From'), findsNothing);

      await tester.scrollUntilVisible(find.text('Quiet hours'), 100);
      await tester.tap(find.text('Quiet hours'));
      await tester.pumpAndSettle();
      expect(repo.docs['alice']!.notifications.quietHours.enabled, isTrue);
      await tester.scrollUntilVisible(find.text('Until'), 100);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('10:00 PM'), findsOneWidget);
      store.detach();
    });
  });
}

/// Never delivers the saved settings (a slow or offline first load).
class _SlowSettingsRepository extends FakeSettingsRepository {
  int saves = 0;

  @override
  Stream<UserSettings> watch(String uid) =>
      StreamController<UserSettings>().stream;

  @override
  Future<void> saveNotifications(
    String uid,
    NotificationSettings settings,
  ) async => saves++;
}

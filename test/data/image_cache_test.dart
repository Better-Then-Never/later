import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/services/app_image_cache.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Storage implements ImageStorageRepository {
  final urls = <String, String?>{};
  bool offline = false;
  int calls = 0;

  @override
  Future<String?> imageUrl(
    String uid,
    ProfileImageKind kind, {
    bool small = false,
  }) async {
    calls++;
    if (offline) throw Exception('offline');
    return urls[uid];
  }

  @override
  Future<void> uploadProfileImage(String uid, Uint8List bytes) async {}

  @override
  Future<void> uploadBackgroundImage(String uid, Uint8List bytes) async {}

  @override
  Future<void> deleteImage(String uid, ProfileImageKind kind) async {}
}

void main() {
  test('decode widths snap to a few buckets', () {
    expect(AppImageCache.decodeWidth(40, 2.625), 192);
    expect(AppImageCache.decodeWidth(48, 3), 192);
    expect(AppImageCache.decodeWidth(180, 2.625), 640);
    expect(AppImageCache.decodeWidth(400, 3), 1600);
    expect(AppImageCache.decodeWidth(2000, 3), 1600);
  });

  group('remembered picture URLs', () {
    late _Storage storage;
    late PreferencesStore prefs;
    late List<String> evicted;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = PreferencesStore();
      await prefs.init();
      storage = _Storage()..urls['bob'] = 'https://img/bob-1';
      evicted = [];
    });

    ProfileImageCache open() => ProfileImageCache(
      storage,
      prefs: prefs,
      evict: (url) async => evicted.add(url),
    );

    Future<void> firstSession() async {
      final cache = open()..attach('alice');
      await cache.resolve('bob', ProfileImageKind.profile);
      cache.detach(); // saves what was found
      await pumpEventQueue();
    }

    test('after a restart the picture shows before any lookup', () async {
      await firstSession();
      storage.offline = true;

      final cache = open()..attach('alice');
      await pumpEventQueue();
      expect(cache.url('bob', ProfileImageKind.profile), 'https://img/bob-1');
      expect(cache.isResolved('bob', ProfileImageKind.profile), isTrue);
      await pumpEventQueue();
      // Offline: the lookup failed, the remembered picture stays.
      expect(cache.url('bob', ProfileImageKind.profile), 'https://img/bob-1');
      cache.detach();
    });

    test('a changed picture replaces the remembered one once', () async {
      await firstSession();
      storage.urls['bob'] = 'https://img/bob-2';

      final cache = open()..attach('alice');
      await pumpEventQueue();
      cache.url('bob', ProfileImageKind.profile);
      await pumpEventQueue();
      expect(cache.url('bob', ProfileImageKind.profile), 'https://img/bob-2');
      expect(evicted, ['https://img/bob-1']);
      final calls = storage.calls;
      cache.url('bob', ProfileImageKind.profile);
      await pumpEventQueue();
      expect(storage.calls, calls, reason: 'looked up once per session');
      cache.detach();
    });

    test('another account on this phone starts empty', () async {
      await firstSession();
      final cache = open()..attach('carol');
      await pumpEventQueue();
      expect(cache.isResolved('bob', ProfileImageKind.profile), isFalse);
      cache.detach();
    });

    test('an upload evicts the old picture', () async {
      final cache = open()..attach('alice');
      await cache.resolve('bob', ProfileImageKind.profile);
      cache.invalidate('bob');
      expect(evicted, ['https://img/bob-1']);
      cache.detach();
    });
  });
}

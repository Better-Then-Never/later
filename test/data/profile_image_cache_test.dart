import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/services/profile_image_cache.dart';

/// Storage that refuses every read while [signedIn] is false, like the real
/// rules do during sign-out.
class _Storage implements ImageStorageRepository {
  bool signedIn = true;
  final urls = <String, String>{'bob': 'https://img/bob'};
  Completer<void>? gate;
  int calls = 0;

  @override
  Future<String?> imageUrl(
    String uid,
    ProfileImageKind kind, {
    bool small = false,
  }) async {
    calls++;
    await gate?.future;
    if (!signedIn) throw Exception('unauthorized');
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
  test(
    'lookups refused while signing out do not reach the next session',
    () async {
      final storage = _Storage();
      final cache = ProfileImageCache(storage)..attach('alice');

      storage.signedIn = false;
      cache.detach();
      // Widgets still on screen ask again: Storage refuses.
      expect(await cache.resolve('bob', ProfileImageKind.profile), isNull);

      storage.signedIn = true;
      cache.attach('bob');
      expect(
        await cache.resolve('bob', ProfileImageKind.profile),
        'https://img/bob',
      );
    },
  );

  test('an answer that arrives after the session changed is dropped', () async {
    final storage = _Storage()..gate = Completer<void>();
    final cache = ProfileImageCache(storage)..attach('alice');
    final pending = cache.resolve('bob', ProfileImageKind.profile);

    storage.signedIn = false;
    cache.detach();
    storage.gate!.complete();
    await pending;

    expect(cache.isResolved('bob', ProfileImageKind.profile), isFalse);
  });

  test('a failure is not retried on every rebuild', () async {
    final storage = _Storage()..signedIn = false;
    final cache = ProfileImageCache(storage)..attach('me');
    await cache.resolve('bob', ProfileImageKind.profile);
    await cache.resolve('bob', ProfileImageKind.profile);
    expect(storage.calls, 1, reason: 'kept for 30 s, then retried');
  });
}

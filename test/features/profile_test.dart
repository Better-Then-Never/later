import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/data/repositories/repositories.dart';
import 'package:later/data/services/profile_image_cache.dart';
import 'package:later/features/profile/profile_image_editor.dart';

import '../fakes/fake_repositories.dart';

class _FailingDelete extends FakeImageStorageRepository {
  @override
  Future<void> deleteImage(String uid, ProfileImageKind kind) =>
      Future.error(Exception('unavailable'));
}

void main() {
  final bytes = Uint8List.fromList([1, 2, 3]);

  test('upload refreshes every avatar of the user (BUG-080)', () async {
    final repo = FakeImageStorageRepository();
    final cache = ProfileImageCache(repo);
    expect(await cache.resolve('me', ProfileImageKind.profile), isNull);

    final editor = ProfileImageEditor(
      uid: 'me',
      kind: ProfileImageKind.profile,
      images: repo,
      cache: cache,
    );
    expect(await editor.upload(bytes), isNull);
    expect(repo.calls, ['upload-profile:me']);
    expect(editor.preview, bytes);
    expect(
      await cache.resolve('me', ProfileImageKind.profile),
      'https://img/me/profile',
      reason: 'the cached "no picture" answer was dropped',
    );
  });

  test('a failed delete reports an error and is not stuck (BUG-081)', () async {
    final editor = ProfileImageEditor(
      uid: 'me',
      kind: ProfileImageKind.background,
      images: _FailingDelete(),
      cache: ProfileImageCache(FakeImageStorageRepository()),
    );
    final failure = await editor.delete();
    expect(failure, isA<AppFailure>());
    expect(failure!.message, 'Failed to delete background picture');
    expect(editor.isBusy, isFalse);
  });

  test('taps while busy are ignored', () async {
    final repo = FakeImageStorageRepository();
    final editor = ProfileImageEditor(
      uid: 'me',
      kind: ProfileImageKind.background,
      images: repo,
      cache: ProfileImageCache(repo),
    );
    final first = editor.upload(bytes);
    expect(editor.isBusy, isTrue);
    await editor.delete();
    await first;
    expect(repo.calls, ['upload-background:me']);
  });
}

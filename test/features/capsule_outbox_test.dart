import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:later/data/models/geo_position.dart';
import 'package:later/data/services/location_service.dart';
import 'package:later/features/capsules/creation/capsule_creation_controller.dart';
import 'package:later/features/capsules/outbox/background_uploads.dart';
import 'package:later/features/capsules/outbox/capsule_outbox.dart';
import 'package:later/features/history/own_capsules_store.dart';
import 'package:later/features/map/current_location.dart';

import '../fakes/fake_repositories.dart';

class _NoLocation extends LocationService {
  const _NoLocation();

  @override
  Future<GeoPosition?> currentPosition({
    Duration timeout = const Duration(seconds: 8),
    bool request = false,
  }) async => null;
}

/// The phone's upload job, recorded.
class _Job extends BackgroundUploads {
  final calls = <String>[];

  @override
  bool get enabled => true;

  @override
  Future<void> schedule({required bool wifiOnly}) async =>
      calls.add('schedule wifiOnly=$wifiOnly');

  @override
  Future<void> cancel() async => calls.add('cancel');
}

/// Real file I/O finishes on the event loop, not in microtasks.
Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late FakeCapsuleRepository repo;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('outbox_test');
    repo = FakeCapsuleRepository();
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  CapsuleOutbox outbox() => CapsuleOutbox(
    repo,
    directory: () async => root,
    retryEvery: const Duration(hours: 1),
  );

  var photos = 0;
  Future<String> photo() async {
    final f = File('${root.path}/camera_${photos++}.jpg');
    await f.writeAsBytes(List.filled(64, 7));
    return f.path;
  }

  CapsuleCreationController creation(String imagePath, CapsuleOutbox box) =>
      CapsuleCreationController(
        ownerId: 'me',
        imagePath: imagePath,
        capsules: repo,
        location: const _NoLocation(),
        currentLocation: CurrentLocation()..update(const GeoPosition(52, 21)),
        outbox: box,
      );

  test('without a connection the capsule waits on the phone (F-26)', () async {
    final box = outbox()..attach('me');
    await box.loading;
    repo.offline = true;
    final path = await photo();
    final c = creation(path, box);
    c.titleController.text = 'Offline';

    expect(await c.save(), isNull, reason: 'no error for the user');
    expect(c.queued, isTrue);
    expect(repo.created, isEmpty);
    final entry = box.pending.single;
    expect(entry.draft.title, 'Offline');
    expect(File(entry.draft.imagePath).existsSync(), isTrue);
    await _until(() => !File(path).existsSync());
    expect(File(path).existsSync(), isFalse, reason: 'camera file cleaned');

    // Shown in the user's list, marked pending.
    final store = OwnCapsulesStore(repo, outbox: box)..attach('me');
    await pumpEventQueue();
    expect(store.capsules.single.pending, isTrue);
    expect(store.capsules.single.title, 'Offline');

    // Back online: uploaded once, with the id it was given.
    repo.offline = false;
    await box.retry();
    expect(repo.created.single.id, entry.id);
    expect(box.pending, isEmpty);
    await box.retry();
    expect(repo.created, hasLength(1), reason: 'no second capsule');
    store
      ..detach()
      ..dispose();
    c.dispose();
    box.dispose();
  });

  test('waiting capsules survive a restart and upload then', () async {
    final first = outbox()..attach('me');
    await first.loading;
    repo.offline = true;
    final c = creation(await photo(), first)..coAuthors = ['pal'];
    await c.save();
    final id = first.pending.single.id;
    first.dispose();

    repo.offline = false;
    final again = outbox()..attach('me');
    await again.loading;
    expect(again.pending, isEmpty);
    expect(repo.created.single.id, id);
    expect(repo.created.single.coAuthors, ['pal'], reason: 'kept on disk');
    again.dispose();
    c.dispose();
  });

  test(
    'another account does not see them; discard removes the files',
    () async {
      final box = outbox()..attach('me');
      await box.loading;
      repo.offline = true;
      final c = creation(await photo(), box);
      await c.save();
      final entry = box.pending.single;

      box
        ..detach()
        ..attach('someone-else');
      await box.loading;
      expect(box.pending, isEmpty);

      box
        ..detach()
        ..attach('me');
      await box.loading;
      expect(box.pending.single.id, entry.id);
      await box.discard(entry.id);
      expect(box.pending, isEmpty);
      expect(File(entry.draft.imagePath).existsSync(), isFalse);
      box.dispose();
      c.dispose();
    },
  );

  test('a refused capsule is tried a few times, not every minute', () async {
    final box = outbox()..attach('me');
    await box.loading;
    repo.offline = true;
    final c = creation(await photo(), box);
    await c.save();
    repo
      ..offline = false
      ..refuse = true
      ..attempts = 0;

    for (var i = 0; i < CapsuleOutbox.maxRefusals + 2; i++) {
      await box.retry();
    }
    expect(repo.attempts, CapsuleOutbox.maxRefusals);
    expect(box.pending, hasLength(1), reason: 'kept for the user');

    // The next sign-in (or app start) tries again.
    repo.refuse = false;
    box
      ..detach()
      ..attach('me');
    await box.loading;
    expect(box.pending, isEmpty);
    expect(repo.created, hasLength(1));
    box.dispose();
    c.dispose();
  });

  test(
    'a loop capsule keeps its frames on the phone and after a restart',
    () async {
      final first = outbox()..attach('me');
      await first.loading;
      repo.offline = true;
      final frames = [await photo(), await photo(), await photo()];
      final c = CapsuleCreationController(
        ownerId: 'me',
        imagePath: frames.first,
        framePaths: frames,
        capsules: repo,
        location: const _NoLocation(),
        currentLocation: CurrentLocation()..update(const GeoPosition(52, 21)),
        outbox: first,
      );
      expect(c.isLoop, isTrue);
      expect(await c.save(), isNull);
      final queued = first.pending.single;
      expect(queued.draft.framePaths, hasLength(3));
      expect(queued.toCapsule().isLoop, isTrue, reason: 'plays from the phone');
      for (final f in queued.draft.framePaths) {
        expect(File(f).existsSync(), isTrue);
      }
      first.dispose();

      // Restarted, still offline: the frames are read back from the folder.
      final again = outbox()..attach('me');
      await again.loading;
      final restored = again.pending.single.draft;
      expect(restored.framePaths, queued.draft.framePaths);
      await again.discard(again.pending.single.id);
      for (final f in restored.framePaths) {
        expect(File(f).existsSync(), isFalse, reason: 'frames cleaned too');
      }
      again.dispose();
      c.dispose();
    },
  );

  test('a capsule for a friend waits too, then goes to the chat', () async {
    final chats = FakeChatRepository();
    final box = CapsuleOutbox(
      repo,
      chats: chats,
      directory: () async => root,
      retryEvery: const Duration(hours: 1),
    )..attach('me');
    await box.loading;
    repo.offline = true;
    final c = CapsuleCreationController(
      ownerId: 'me',
      imagePath: await photo(),
      capsules: repo,
      location: const _NoLocation(),
      currentLocation: CurrentLocation()..update(const GeoPosition(52, 21)),
      recipientId: 'bob',
      chats: chats,
      outbox: box,
    );
    expect(await c.save(), isNull);
    expect(c.queued, isTrue);
    final waiting = box.pending.single;
    expect(waiting.draft.recipientId, 'bob');
    expect(waiting.toCapsule().sharedWith, ['me', 'bob']);
    expect(chats.calls, isEmpty);

    // After a restart: the recipient was kept on disk.
    box.dispose();
    repo.offline = false;
    final again = CapsuleOutbox(
      repo,
      chats: chats,
      directory: () async => root,
      retryEvery: const Duration(hours: 1),
    )..attach('me');
    await again.loading;
    expect(again.pending, isEmpty);
    expect(chats.calls, ['capsule:me->bob:${waiting.id}']);
    again.dispose();
    c.dispose();
  });

  test('waits grow while offline, up to the cap; Wi-Fi only waits', () async {
    var metered = true;
    var wifiOnly = true;
    final box = CapsuleOutbox(
      repo,
      directory: () async => root,
      retryEvery: const Duration(hours: 1),
      maxDelay: const Duration(hours: 5),
      wifiOnly: () => wifiOnly,
      metered: () async => metered,
    )..attach('me');
    await box.loading;
    repo.offline = true;
    final c = creation(await photo(), box);
    await c.save();
    expect(box.nextDelay, const Duration(hours: 1));

    // On mobile data with "Wi-Fi only": nothing is tried.
    final attempts = repo.attempts;
    await box.retry();
    expect(box.waitingForWifi, isTrue);
    expect(repo.attempts, attempts);

    wifiOnly = false;
    await box.retry();
    expect(box.waitingForWifi, isFalse);
    expect(box.nextDelay, const Duration(hours: 2));
    await box.retry();
    expect(box.nextDelay, const Duration(hours: 4));
    await box.retry();
    expect(box.nextDelay, const Duration(hours: 5), reason: 'capped');

    metered = false;
    repo.offline = false;
    await box.retry();
    expect(box.pending, isEmpty);
    expect(box.nextDelay, const Duration(hours: 1), reason: 'reset');
    box.dispose();
    c.dispose();
  });

  test('leaving the app hands the uploads to the phone\'s job', () async {
    final job = _Job();
    final box = CapsuleOutbox(
      repo,
      directory: () async => root,
      retryEvery: const Duration(milliseconds: 20),
      background: job,
      wifiOnly: () => true,
    )..attach('me');
    await box.loading;
    repo.offline = true;
    final c = creation(await photo(), box);
    await c.save();
    final tries = repo.attempts;

    box.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(job.calls, ['schedule wifiOnly=true']);
    // The app's own timer rests while the job has it.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(repo.attempts, tries);

    repo.offline = false;
    box.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(job.calls.last, 'cancel');
    await _until(() => box.pending.isEmpty);
    expect(box.pending, isEmpty, reason: 'the app took over again');
    box.dispose();
    c.dispose();
  });

  test('connection errors are told apart from refusals', () {
    expect(CapsuleOutbox.isOffline(const SocketException('x')), isTrue);
    expect(CapsuleOutbox.isOffline(StateError('x')), isFalse);
  });
}

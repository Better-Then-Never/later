import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/session/session_scoped.dart';
import '../../../data/models/capsule.dart';
import '../../../data/models/geo_position.dart';
import '../../../data/repositories/repositories.dart';

/// A capsule saved on this phone while there was no connection.
class PendingCapsule {
  const PendingCapsule({required this.draft, required this.queuedAt});

  /// With its final id and the photo in the outbox folder.
  final CapsuleDraft draft;
  final DateTime queuedAt;

  String get id => draft.id!;

  /// How it shows in the user's list until it is uploaded.
  Capsule toCapsule() => Capsule(
    id: id,
    ownerId: draft.ownerId,
    title: draft.title,
    description: draft.description,
    location: draft.location,
    privacy: draft.privacy,
    color: draft.color,
    // The photo on the phone until it is uploaded.
    imageUrl: Uri.file(draft.imagePath).toString(),
    frames: [for (final f in draft.framePaths) Uri.file(f).toString()],
    frameDelayMs: draft.frameDelayMs,
    createdAt: queuedAt,
    capturedAt: draft.capturedAt,
    openAt: draft.openAt,
    isScheduled: draft.openAt != null,
    pending: true,
  );
}

/// Capsules made offline (F-26): the photo and the draft are kept in the
/// app's documents folder, per account, and uploaded when a connection is
/// back: at sign-in, when the app comes to the foreground, and every
/// minute while something waits. The capsule id is fixed when queued, so a
/// retry never creates a second capsule. A capsule for a friend is not
/// queued (its chat post needs the connection); it fails as before.
class CapsuleOutbox extends ChangeNotifier
    with WidgetsBindingObserver
    implements SessionScoped {
  CapsuleOutbox(
    this._repo, {
    Future<Directory> Function()? directory,
    this.retryEvery = const Duration(minutes: 1),
  }) : _directory = directory ?? getApplicationDocumentsDirectory;

  final CapsuleRepository _repo;
  final Future<Directory> Function() _directory;
  final Duration retryEvery;

  /// Refusals in a row after which a capsule waits for the next sign-in or
  /// app start: each attempt uploads the photo again, so one the server
  /// keeps refusing must not retry every minute.
  static const maxRefusals = 3;

  String? _uid;
  List<PendingCapsule> _pending = const [];
  final Map<String, int> _refusals = {};
  Timer? _timer;
  bool _uploading = false;
  bool _observing = false;

  List<PendingCapsule> get pending => _pending;

  /// The load (and first upload attempt) started by the last [attach].
  Future<void> get loading => _loading;
  Future<void> _loading = Future.value();

  /// Whether [e] means "no connection" rather than "refused".
  static bool isOffline(Object e) =>
      e is SocketException ||
      e is TimeoutException ||
      (e is FirebaseException &&
          const {
            'unavailable',
            'network-request-failed',
            'deadline-exceeded',
            'retry-limit-exceeded',
          }.contains(e.code));

  Future<Directory> _folder(String uid) async {
    final root = await _directory();
    final dir = Directory('${root.path}/outbox/$uid');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  @override
  void attach(String uid) {
    _uid = uid;
    _refusals.clear();
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    _loading = _load(uid);
  }

  @override
  void detach() {
    _uid = null;
    _timer?.cancel();
    _timer = null;
    _pending = const [];
    notifyListeners();
  }

  @override
  Future<void> beforeSignOut(String uid) async {}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(retry());
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load(String uid) async {
    try {
      final dir = await _folder(uid);
      final loaded = <PendingCapsule>[];
      await for (final f in dir.list()) {
        if (f is! File || !f.path.endsWith('.json')) continue;
        try {
          final json = jsonDecode(await f.readAsString()) as Map;
          loaded.add(_fromJson(json.cast<String, Object?>(), dir.path));
        } catch (e) {
          AppLogger.warning('Unreadable outbox entry ${f.path}', error: e);
        }
      }
      if (_uid != uid) return;
      loaded.sort((a, b) => a.queuedAt.compareTo(b.queuedAt));
      _pending = loaded;
      notifyListeners();
      await retry();
    } catch (e) {
      AppLogger.warning('Could not read the outbox', error: e);
    }
  }

  /// Keeps [draft] (which has an id) until it can be uploaded. Its photo is
  /// copied into the outbox folder; the original may be deleted afterwards.
  Future<void> enqueue(CapsuleDraft draft) async {
    final uid = _uid;
    final id = draft.id;
    if (uid == null || id == null) throw StateError('No session or id');
    final dir = await _folder(uid);
    final photo = '${dir.path}/$id.jpg';
    await File(draft.imagePath).copy(photo);
    // A loop capsule's frames come along.
    final frames = <String>[];
    for (var i = 0; i < draft.framePaths.length; i++) {
      final frame = '${dir.path}/${id}_frame_$i.jpg';
      await File(draft.framePaths[i]).copy(frame);
      frames.add(frame);
    }
    final entry = PendingCapsule(
      draft: draft.copyWith(imagePath: photo, framePaths: frames),
      queuedAt: DateTime.now(),
    );
    await File(
      '${dir.path}/$id.json',
    ).writeAsString(jsonEncode(_toJson(entry)));
    _pending = [..._pending, entry];
    notifyListeners();
    _schedule();
  }

  /// Tries every waiting capsule once; stops at the first connection error.
  Future<void> retry() async {
    final uid = _uid;
    if (uid == null || _uploading || _pending.isEmpty) return;
    _uploading = true;
    try {
      for (final entry in [..._pending]) {
        if (_uid != uid) return;
        if (_gaveUp(entry)) continue;
        try {
          await _repo.create(entry.draft);
          AppLogger.info('Outbox capsule ${entry.id} uploaded');
          await _remove(uid, entry);
        } catch (e) {
          if (isOffline(e)) break;
          // Refused (e.g. rules): keep it; the user can delete it from the
          // list. Right after a reconnect this can be a passing error, so it
          // is tried again, up to [maxRefusals] times. Logged to be visible.
          _refusals[entry.id] = (_refusals[entry.id] ?? 0) + 1;
          AppLogger.warning('Outbox capsule ${entry.id} refused', error: e);
        }
      }
    } finally {
      _uploading = false;
      _schedule();
    }
  }

  /// Gives up on a waiting capsule (deleted from the list).
  Future<void> discard(String id) async {
    final uid = _uid;
    final entry = _pending.where((p) => p.id == id).firstOrNull;
    if (uid == null || entry == null) return;
    await _remove(uid, entry);
  }

  bool _gaveUp(PendingCapsule entry) =>
      (_refusals[entry.id] ?? 0) >= maxRefusals;

  Future<void> _remove(String uid, PendingCapsule entry) async {
    _refusals.remove(entry.id);
    _pending = _pending.where((p) => p.id != entry.id).toList();
    notifyListeners();
    try {
      final dir = await _folder(uid);
      for (final name in [
        '${entry.id}.json',
        '${entry.id}.jpg',
        for (var i = 0; i < entry.draft.framePaths.length; i++)
          '${entry.id}_frame_$i.jpg',
      ]) {
        final f = File('${dir.path}/$name');
        if (await f.exists()) await f.delete();
      }
    } catch (e) {
      AppLogger.debug('Could not clean the outbox: $e');
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    if (_uid == null || _pending.every(_gaveUp)) return;
    _timer = Timer(retryEvery, () => unawaited(retry()));
  }

  static Map<String, Object?> _toJson(PendingCapsule p) {
    final d = p.draft;
    return {
      'id': d.id,
      'queuedAt': p.queuedAt.toIso8601String(),
      'ownerId': d.ownerId,
      'title': d.title,
      'description': d.description,
      'privacy': d.privacy.name,
      'color': d.color.name,
      'lat': d.location.latitude,
      'lng': d.location.longitude,
      'openAt': d.openAt?.toIso8601String(),
      'capturedAt': d.capturedAt?.toIso8601String(),
      'utcOffsetMinutes': d.utcOffsetMinutes,
      'showAuthor': d.showAuthor,
      if (d.coAuthors.isNotEmpty) 'coAuthors': d.coAuthors,
      'allowComments': d.allowComments,
      'allowReactions': d.allowReactions,
      'locationPrecision': d.locationPrecision.name,
      'placeName': d.placeName,
      // Frame files are named after the capsule; only their number is kept.
      if (d.framePaths.isNotEmpty) 'frames': d.framePaths.length,
      if (d.framePaths.isNotEmpty) 'frameDelayMs': d.frameDelayMs,
    };
  }

  static PendingCapsule _fromJson(Map<String, Object?> j, String folder) {
    DateTime? date(Object? v) => v is String ? DateTime.tryParse(v) : null;
    final id = j['id']! as String;
    return PendingCapsule(
      queuedAt: date(j['queuedAt']) ?? DateTime.now(),
      draft: CapsuleDraft(
        id: id,
        ownerId: j['ownerId']! as String,
        title: j['title']! as String,
        description: j['description'] as String?,
        privacy: CapsulePrivacy.parse(j['privacy']),
        color: CapsuleColor.parse(j['color']),
        location: GeoPosition(
          (j['lat']! as num).toDouble(),
          (j['lng']! as num).toDouble(),
        ),
        imagePath: '$folder/$id.jpg',
        openAt: date(j['openAt']),
        capturedAt: date(j['capturedAt']),
        utcOffsetMinutes: j['utcOffsetMinutes'] as int?,
        showAuthor: j['showAuthor'] as bool? ?? true,
        coAuthors: [
          for (final uid in (j['coAuthors'] as List?) ?? const [])
            if (uid is String) uid,
        ],
        allowComments: j['allowComments'] as bool? ?? true,
        allowReactions: j['allowReactions'] as bool? ?? true,
        locationPrecision: LocationPrecision.parse(j['locationPrecision']),
        placeName: j['placeName'] as String?,
        framePaths: [
          for (var i = 0; i < ((j['frames'] as num?)?.toInt() ?? 0); i++)
            '$folder/${id}_frame_$i.jpg',
        ],
        frameDelayMs:
            (j['frameDelayMs'] as num?)?.toInt() ?? Capsule.defaultFrameDelayMs,
      ),
    );
  }
}

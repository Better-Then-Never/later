import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/logging/app_logger.dart';
import '../models/capsule.dart';
import '../repositories/repositories.dart';
import '../services/image_processor.dart';
import 'firestore_mappers.dart';

class FirebaseCapsuleRepository implements CapsuleRepository {
  FirebaseCapsuleRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    ImageProcessor processor = const ImageProcessor(),
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _storageOverride = storage,
       _processor = processor;

  final FirebaseFirestore _db;
  final FirebaseStorage? _storageOverride;

  // Resolved lazily so query-only use (and tests) need no Storage instance.
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;
  final ImageProcessor _processor;

  static const _whereInLimit = 30;
  static const _batchSize = 450;

  CollectionReference<Map<String, dynamic>> get _capsules =>
      _db.collection(FirestorePaths.capsules);

  Reference _imageRef(String ownerId, String capsuleId) =>
      _storage.ref('userdata/$ownerId/capsules/$capsuleId/image.jpg');

  List<Capsule> _map(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs.map((d) => FirestoreMappers.capsule(d.id, d.data())).toList();

  @override
  Stream<List<Capsule>> watchOwn(String uid) => _capsules
      .where('ownerId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(_map);

  @override
  Future<Capsule?> getById(String id) async {
    try {
      final doc = await _capsules.doc(id).get();
      final data = doc.data();
      return data == null ? null : FirestoreMappers.capsule(doc.id, data);
    } on FirebaseException catch (e) {
      // Not visible to this user (private or no longer a friend).
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  @override
  Future<List<Capsule>> sharedBy(String ownerId, {int limit = 30}) async {
    // Two equality queries (no composite index; each passes the rules on its
    // own), merged and sorted here.
    final snaps = await Future.wait([
      for (final privacy in [CapsulePrivacy.public, CapsulePrivacy.friends])
        _capsules
            .where('ownerId', isEqualTo: ownerId)
            .where('privacy', isEqualTo: privacy.name)
            .limit(limit)
            .get(),
    ]);
    final all = [for (final s in snaps) ..._map(s)]
      ..sort(
        (a, b) =>
            (b.takenAt ?? DateTime(0)).compareTo(a.takenAt ?? DateTime(0)),
      );
    return all;
  }

  @override
  Stream<Capsule?> watchById(String id) => _capsules
      .doc(id)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        return data == null ? null : FirestoreMappers.capsule(doc.id, data);
      })
      .handleError((Object e) {
        // No longer visible (unfriended, privacy changed): the stream ends.
        if (e is! FirebaseException || e.code != 'permission-denied') throw e;
      });

  @override
  Stream<List<Capsule>> watchFriends(List<String> friendIds) {
    final ids = friendIds.toSet().toList();
    if (ids.isEmpty) return Stream.value(const []);
    final chunks = <List<String>>[
      for (var i = 0; i < ids.length; i += _whereInLimit)
        ids.sublist(
          i,
          i + _whereInLimit > ids.length ? ids.length : i + _whereInLimit,
        ),
    ];
    final streams = chunks
        .map(
          (chunk) => _capsules
              .where('ownerId', whereIn: chunk)
              .where('privacy', isEqualTo: CapsulePrivacy.friends.name)
              .snapshots()
              .map(_map),
        )
        .toList();
    return _combineLatest(streams);
  }

  @override
  Stream<List<Capsule>> watchPublicInBand(
    double minLat,
    double maxLat, {
    int limit = 300,
  }) => _capsules
      .where('privacy', isEqualTo: CapsulePrivacy.public.name)
      // GeoPoints sort by latitude first, so this is a latitude band.
      .where('location', isGreaterThanOrEqualTo: GeoPoint(minLat, -180))
      .where('location', isLessThanOrEqualTo: GeoPoint(maxLat, 180))
      .limit(limit)
      .snapshots()
      .map(_map);

  @override
  String newCapsuleId() => _capsules.doc().id;

  @override
  Future<Capsule> create(CapsuleDraft draft) async {
    final id = draft.id;
    final doc = id == null ? _capsules.doc() : _capsules.doc(id);
    if (id != null) {
      // A retry after an attempt whose answer was lost: done already.
      final existing = await doc.get();
      final data = existing.data();
      if (data != null) return FirestoreMappers.capsule(doc.id, data);
    }
    // An attempt that the app gave up on (no connection: the capsule went to
    // the outbox) must not keep uploading for the default 10 minutes.
    _storage.setMaxUploadRetryTime(const Duration(seconds: 45));
    final imageRef = _imageRef(draft.ownerId, doc.id);
    final bytes = await _processor.capsuleJpegFromFile(draft.imagePath);
    await imageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final imageUrl = await imageRef.getDownloadURL();
    try {
      await _setNew(
        doc,
        FirestoreMappers.newCapsule(draft, imageUrl: imageUrl),
      );
    } catch (_) {
      // Do not leave an orphaned image behind.
      await _deleteImage(imageRef);
      rethrow;
    }
    return Capsule(
      id: doc.id,
      ownerId: draft.ownerId,
      title: draft.title,
      description: draft.description,
      imageUrl: imageUrl,
      location: draft.location,
      privacy: draft.privacy,
      color: draft.color,
      createdAt: DateTime.now(),
      openAt: draft.openAt,
      isScheduled: draft.openAt != null,
      sharedWith: [
        if (draft.recipientId != null) ...[draft.ownerId, draft.recipientId!],
      ],
      capturedAt: draft.capturedAt,
      utcOffsetMinutes: draft.utcOffsetMinutes,
      showAuthor: draft.showAuthor,
      allowComments: draft.allowComments,
      allowReactions: draft.allowReactions,
      locationPrecision: draft.locationPrecision,
      placeName: draft.placeName,
    );
  }

  /// Rules deployed before the added capsule fields reject them: the capsule
  /// is then saved without them, once, so the app may ship before the rules.
  Future<void> _setNew(
    DocumentReference<Map<String, dynamic>> doc,
    Map<String, dynamic> data,
  ) async {
    try {
      await doc.set(data);
    } on FirebaseException catch (e) {
      final legacy = FirestoreMappers.legacyCapsule(data);
      if (e.code != 'permission-denied' || legacy.length == data.length) {
        rethrow;
      }
      AppLogger.warning('Capsule rejected with the added fields, retrying');
      await doc.set(legacy);
    }
  }

  @override
  Future<void> delete(Iterable<Capsule> capsules) async {
    final list = capsules.toList();
    for (var i = 0; i < list.length; i += _batchSize) {
      final batch = _db.batch();
      for (final c in list.skip(i).take(_batchSize)) {
        batch.delete(_capsules.doc(c.id));
      }
      await batch.commit();
    }
    await Future.wait(
      list.map((c) => _deleteImage(_imageRef(c.ownerId, c.id))),
    );
  }

  Future<void> _deleteImage(Reference ref) async {
    try {
      await ref.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') {
        AppLogger.warning('Could not delete ${ref.fullPath}', error: e);
      }
    }
  }

  /// Emits the concatenation of the latest value of every stream once each
  /// has emitted at least once.
  static Stream<List<Capsule>> _combineLatest(
    List<Stream<List<Capsule>>> streams,
  ) {
    if (streams.length == 1) return streams.first;
    late StreamController<List<Capsule>> controller;
    final latest = List<List<Capsule>?>.filled(streams.length, null);
    final subscriptions = <StreamSubscription<List<Capsule>>>[];
    controller = StreamController<List<Capsule>>(
      onListen: () {
        for (var i = 0; i < streams.length; i++) {
          subscriptions.add(
            streams[i].listen((value) {
              latest[i] = value;
              if (latest.every((l) => l != null)) {
                controller.add([for (final l in latest) ...l!]);
              }
            }, onError: controller.addError),
          );
        }
      },
      onCancel: () async {
        for (final s in subscriptions) {
          await s.cancel();
        }
        await controller.close();
      },
    );
    return controller.stream;
  }
}

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
  Future<Capsule> create(CapsuleDraft draft) async {
    final doc = _capsules.doc();
    final imageRef = _imageRef(draft.ownerId, doc.id);
    final bytes = await _processor.capsuleJpegFromFile(draft.imagePath);
    await imageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    final imageUrl = await imageRef.getDownloadURL();
    try {
      await doc.set(FirestoreMappers.newCapsule(draft, imageUrl: imageUrl));
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
      isScheduled: true,
    );
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

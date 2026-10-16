import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';
import '../repositories/repositories.dart';
import 'firestore_mappers.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Firestore batches are limited to 500 writes.
  static const _batchSize = 450;

  CollectionReference<Map<String, dynamic>> _collection(String uid) => _db
      .collection(FirestorePaths.users)
      .doc(uid)
      .collection(FirestorePaths.notifications);

  @override
  Stream<List<AppNotification>> watch(String uid, {int limit = 100}) =>
      _collection(uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snap) => snap.docs
                .map((d) => FirestoreMappers.notification(d.id, d.data()))
                .toList(),
          );

  Future<void> _inBatches(
    Iterable<String> ids,
    void Function(WriteBatch batch, DocumentReference<Map<String, dynamic>> ref)
    op,
    String uid,
  ) async {
    final list = ids.toList();
    for (var i = 0; i < list.length; i += _batchSize) {
      final batch = _db.batch();
      for (final id in list.skip(i).take(_batchSize)) {
        op(batch, _collection(uid).doc(id));
      }
      await batch.commit();
    }
  }

  @override
  Future<void> markRead(String uid, Iterable<String> ids) =>
      _inBatches(ids, (batch, ref) => batch.update(ref, {'isRead': true}), uid);

  @override
  Future<void> delete(String uid, Iterable<String> ids) =>
      _inBatches(ids, (batch, ref) => batch.delete(ref), uid);

  @override
  Future<void> createFollowNotification({
    required String targetUid,
    required String fromUid,
    required String fromUserName,
  }) => _collection(targetUid).add({
    'type': 'follow',
    'fromUserId': fromUid,
    'fromUserName': fromUserName,
    'fromUserAvatar': '',
    'message': 'started following you',
    'timestamp': FieldValue.serverTimestamp(),
    'isRead': false,
  });
}

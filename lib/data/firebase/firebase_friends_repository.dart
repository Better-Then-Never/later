import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/friend_request.dart';
import '../repositories/repositories.dart';
import 'firestore_mappers.dart';

class FirebaseFriendsRepository implements FriendsRepository {
  FirebaseFriendsRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection(FirestorePaths.friendRequests);

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection(FirestorePaths.users).doc(uid);

  Stream<List<FriendRequest>> _pending(String field, String uid) => _requests
      .where(field, isEqualTo: uid)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => FirestoreMappers.friendRequest(d.data()))
            .toList(),
      );

  @override
  Stream<List<FriendRequest>> watchOutgoingPending(String uid) =>
      _pending('fromUserId', uid);

  @override
  Stream<List<FriendRequest>> watchIncomingPending(String uid) =>
      _pending('toUserId', uid);

  @override
  Future<void> sendRequest({required String from, required String to}) =>
      _requests.doc(FriendRequest.idFor(from, to)).set({
        'fromUserId': from,
        'toUserId': to,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> cancelRequest({required String from, required String to}) =>
      _requests.doc(FriendRequest.idFor(from, to)).delete();

  @override
  Future<void> rejectRequest({required String from, required String to}) =>
      _requests.doc(FriendRequest.idFor(from, to)).delete();

  @override
  Future<void> acceptRequest({required String from, required String to}) {
    // One atomic write: the security rules only allow adding the caller to
    // the sender's `friends` when this batch also marks the request accepted.
    final batch = _db.batch()
      ..update(_requests.doc(FriendRequest.idFor(from, to)), {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      })
      ..set(_user(to), {
        'friends': FieldValue.arrayUnion([from]),
      }, SetOptions(merge: true))
      ..set(_user(from), {
        'friends': FieldValue.arrayUnion([to]),
      }, SetOptions(merge: true));
    return batch.commit();
  }

  @override
  Future<void> removeFriend({required String me, required String friend}) {
    final batch = _db.batch()
      ..set(_user(me), {
        'friends': FieldValue.arrayRemove([friend]),
      }, SetOptions(merge: true))
      ..set(_user(friend), {
        'friends': FieldValue.arrayRemove([me]),
      }, SetOptions(merge: true))
      // Deleting a missing document is a no-op, so no reads are needed.
      ..delete(_requests.doc(FriendRequest.idFor(me, friend)))
      ..delete(_requests.doc(FriendRequest.idFor(friend, me)));
    return batch.commit();
  }

  @override
  Future<bool> isFollowing({required String me, required String target}) async {
    final doc = await _user(
      me,
    ).collection(FirestorePaths.following).doc(target).get();
    return doc.exists;
  }

  @override
  Future<void> follow({
    required String me,
    required String target,
    required String myUsername,
  }) {
    final batch = _db.batch()
      ..set(_user(me).collection(FirestorePaths.following).doc(target), {
        'followedAt': FieldValue.serverTimestamp(),
        'notificationsEnabled': true,
      })
      ..set(_user(target).collection(FirestorePaths.followers).doc(me), {
        'followedAt': FieldValue.serverTimestamp(),
      });
    return batch.commit();
  }

  @override
  Future<void> unfollow({required String me, required String target}) {
    final batch = _db.batch()
      ..delete(_user(me).collection(FirestorePaths.following).doc(target))
      ..delete(_user(target).collection(FirestorePaths.followers).doc(me));
    return batch.commit();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    final requestId = '${fromUserId}_$toUserId';
    await _firestore.collection('friend_requests').doc(requestId).set({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest(
    String requestId,
    String fromUserId,
    String toUserId,
  ) async {
    final batch = _firestore.batch();
    batch.update(_firestore.collection('friend_requests').doc(requestId), {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_firestore.collection('users').doc(fromUserId), {
      'friends': FieldValue.arrayUnion([toUserId]),
    });
    batch.update(_firestore.collection('users').doc(toUserId), {
      'friends': FieldValue.arrayUnion([fromUserId]),
    });
    await batch.commit();
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      final doc = await _firestore
          .collection('friend_requests')
          .doc(requestId)
          .get();
      if (!doc.exists) {
        throw Exception('Friend request not found');
      }

      await _firestore.collection('friend_requests').doc(requestId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelFriendRequest(String fromUserId, String toUserId) async {
  final requestId = '${fromUserId}_$toUserId';
  
  try {
    final doc = await _firestore
        .collection('friend_requests')
        .doc(requestId)
        .get();
        
    if (!doc.exists) {
      throw Exception('Friend request not found');
    }

    await _firestore.collection('friend_requests').doc(requestId).delete();
  } catch (e) {
    rethrow;
  }
}

  Future<void> removeFriend(String currentUserId, String friendUserId) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('users').doc(currentUserId), {
      'friends': FieldValue.arrayRemove([friendUserId]),
    });
    batch.update(_firestore.collection('users').doc(friendUserId), {
      'friends': FieldValue.arrayRemove([currentUserId]),
    });
    final requestId1 = '${currentUserId}_$friendUserId';
    final requestId2 = '${friendUserId}_$currentUserId';

    final doc1 = await _firestore
        .collection('friend_requests')
        .doc(requestId1)
        .get();
    if (doc1.exists) {
      batch.delete(_firestore.collection('friend_requests').doc(requestId1));
    }

    final doc2 = await _firestore
        .collection('friend_requests')
        .doc(requestId2)
        .get();
    if (doc2.exists) {
      batch.delete(_firestore.collection('friend_requests').doc(requestId2));
    }

    await batch.commit();
  }

  Stream<QuerySnapshot> getPendingRequests(String userId) {
    return _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<bool> requestExists(String fromUserId, String toUserId) async {
    final requestId = '${fromUserId}_$toUserId';
    final reverseRequestId = '${toUserId}_$fromUserId';

    final doc1 = await _firestore
        .collection('friend_requests')
        .doc(requestId)
        .get();
    final doc2 = await _firestore
        .collection('friend_requests')
        .doc(reverseRequestId)
        .get();

    bool doc1Pending = doc1.exists && doc1.data()?['status'] == 'pending';
    bool doc2Pending = doc2.exists && doc2.data()?['status'] == 'pending';

    return doc1Pending || doc2Pending;
  }

  Future<String?> getRequestStatus(String fromUserId, String toUserId) async {
    final requestId = '${fromUserId}_$toUserId';
    final reverseRequestId = '${toUserId}_$fromUserId';

    final doc1 = await _firestore
        .collection('friend_requests')
        .doc(requestId)
        .get();
    if (doc1.exists) {
      final status = doc1.data()?['status'];
      if (status == 'pending') {
        return status;
      }
    }

    final doc2 = await _firestore
        .collection('friend_requests')
        .doc(reverseRequestId)
        .get();
    if (doc2.exists) {
      final status = doc2.data()?['status'];
      if (status == 'pending') {
        return status;
      }
    }

    return null;
  }

  Future<bool> areFriends(String userId1, String userId2) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId1).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        final friends = List<String>.from(userData?['friends'] ?? []);
        return friends.contains(userId2);
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
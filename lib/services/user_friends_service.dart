import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class UserFriendsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Set<String> _friends = {};
  final Set<String> _sentRequests = {};
  final Set<String> _receivedRequests = {};
  final Set<String> _removedFromSuggested = {};

  Set<String> get friends => _friends;
  Set<String> get sentRequests => _sentRequests;
  Set<String> get receivedRequests => _receivedRequests;
  Set<String> get removedFromSuggested => _removedFromSuggested;

  StreamSubscription<QuerySnapshot>? _sentRequestsSub;
  StreamSubscription<QuerySnapshot>? _receivedRequestsSub;
  StreamSubscription<DocumentSnapshot>? _friendsSub;  

  UserFriendsService() {
    init();
  }

  Future<void> init() async {
    await refreshFriends();
    _listenSentRequests();
    _listenReceivedRequests();
    _listenFriends();
  }

  Future<bool> areFriends(String userId) async {
    return _friends.contains(userId);
  }

  bool requestExists(String fromUserId, String toUserId) {
    return _sentRequests.contains(toUserId) ||
        _receivedRequests.contains(fromUserId);
  }

  int receivedRequestsCount() {
    return _receivedRequests.length;
  }

  List<String> getSentRequestsList() {
    return _sentRequests.toList();
  }

  void _listenFriends() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    _friendsSub?.cancel();

    _friendsSub = _firestore.collection('users').doc(currentUserId).snapshots().listen((doc) {
      final data = doc.data();
      if (data == null) return;

      final updatedFriends = Set<String>.from(data['friends'] ?? []);

      if (!SetEquality().equals(_friends, updatedFriends)) {
        _friends
          ..clear()
          ..addAll(updatedFriends);
        notifyListeners();
      }
    });
  }  

  void _listenSentRequests() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    _sentRequestsSub?.cancel();

    _sentRequestsSub = _firestore
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          _sentRequests.clear();
          for (var doc in snapshot.docs) {
            _sentRequests.add(doc['toUserId']);
          }
          notifyListeners();
        });
  }

  void _listenReceivedRequests() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    _receivedRequestsSub?.cancel();

    _receivedRequestsSub = _firestore
        .collection('friend_requests')
        .where('toUserId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
          _receivedRequests.clear();
          for (var doc in snapshot.docs) {
            _receivedRequests.add(doc['fromUserId']);
          }
          notifyListeners();
        });
  }

  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    final requestId = '${fromUserId}_$toUserId';
    await _firestore.collection('friend_requests').doc(requestId).set({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _sentRequests.add(toUserId);
    notifyListeners();
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

    _friends.add(fromUserId);
    _sentRequests.remove(toUserId);
    _receivedRequests.remove(fromUserId);
    notifyListeners();
  }

  Future<void> rejectFriendRequest(String requestId, String fromUserId) async {
    try {
      await _firestore.collection('friend_requests').doc(requestId).delete();
      _receivedRequests.remove(fromUserId);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelFriendRequest(String fromUserId, String toUserId) async {
    final requestId = '${fromUserId}_$toUserId';
    final doc = await _firestore
        .collection('friend_requests')
        .doc(requestId)
        .get();
    if (!doc.exists) return;

    await _firestore.collection('friend_requests').doc(requestId).delete();
    _sentRequests.remove(toUserId);
    notifyListeners();
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
    if (doc1.exists)
      batch.delete(_firestore.collection('friend_requests').doc(requestId1));

    final doc2 = await _firestore
        .collection('friend_requests')
        .doc(requestId2)
        .get();
    if (doc2.exists)
      batch.delete(_firestore.collection('friend_requests').doc(requestId2));

    await batch.commit();

    _friends.remove(friendUserId);
    _sentRequests.remove(friendUserId);
    _receivedRequests.remove(friendUserId);
    _removedFromSuggested.add(friendUserId);
    notifyListeners();
  }

  void removeSuggestedFriend(String userId) {
    _removedFromSuggested.add(userId);
    notifyListeners();
  }

  Future<void> refreshFriends() async {
    _friends.clear();
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final doc = await _firestore.collection('users').doc(currentUserId).get();
    final data = doc.data();
    if (data != null && data['friends'] != null) {
      _friends.addAll(List<String>.from(data['friends']));
    }
    notifyListeners();
  }

  Stream<List<Map<String, dynamic>>> getSuggestedFriends({
    required String currentUserId,
    String searchQuery = '',
  }) {
    Query query = _firestore
        .collection('users')
        .where(FieldPath.documentId, isNotEqualTo: currentUserId);

    if (searchQuery.isNotEmpty) {
      query = query
          .where('username', isGreaterThanOrEqualTo: searchQuery)
          .where('username', isLessThanOrEqualTo: searchQuery + '\uf8ff');
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => !_friends.contains(doc.id))
          .where((doc) => !_removedFromSuggested.contains(doc.id))
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return {
              'id': doc.id,
              'name': data['name'] ?? '',
              'username': data['username'] ?? '',
            };
          })
          .toList();
    });
  }

  void onLogout() {
    _sentRequestsSub?.cancel();
    _receivedRequestsSub?.cancel();

    _friends.clear();
    _sentRequests.clear();
    _receivedRequests.clear();
    _removedFromSuggested.clear();

    notifyListeners();
  }

  @override
  void dispose() {
    _sentRequestsSub?.cancel();
    _receivedRequestsSub?.cancel();
    super.dispose();
  }
}

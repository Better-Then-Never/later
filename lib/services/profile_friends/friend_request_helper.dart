import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequestHelper {
  static Stream<int> getReceivedRequestsCount(String uid) {
    return FirebaseFirestore.instance
        .collection('friend_requests')
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  
  static Stream<QuerySnapshot> getSentRequests(String uid) {
    return FirebaseFirestore.instance
        .collection('friend_requests')
        .where('fromUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')  
        .snapshots();
  }
  
  static Stream<QuerySnapshot> getReceivedRequests(String uid) {
    return FirebaseFirestore.instance
        .collection('friend_requests')
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }
}
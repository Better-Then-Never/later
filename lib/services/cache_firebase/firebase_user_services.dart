import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class FirebaseUserService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> _friends = [];

  List<String> get friends => _friends;
  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  Stream<User?> get userStream => _auth.authStateChanges();

  Stream<String?> get nameStream {
    if (uid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['name'] as String?);
  }

  Future<void> refreshFriends() async {
    _friends.clear();
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();
    if (data != null && data['friends'] != null) {
      _friends.addAll(List<String>.from(data['friends']));
    }
    notifyListeners();
  }

  Future<void> addFriend(String friendUserId) async {
    final currentUserId = uid;
    if (currentUserId == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({
          'friends': FieldValue.arrayUnion([friendUserId]),
        });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(friendUserId)
        .update({
          'friends': FieldValue.arrayUnion([currentUserId]),
        });

    await refreshFriends();
  }
}

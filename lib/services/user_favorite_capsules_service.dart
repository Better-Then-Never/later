import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FavoriteCapsuleService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Set<String> _favoriteIds = {};
  String? _uid;

  Set<String> get favorites => _favoriteIds;
  bool isFavorite(String capsuleId) => _favoriteIds.contains(capsuleId);

  Future<void> loadFavorites(String uid) async {
    _uid = uid;

    final doc = await _firestore.collection('users').doc(uid).get();
    final data = doc.data();

    _favoriteIds = Set<String>.from(data?['favorites'] ?? []);
    notifyListeners();
  }

  Future<void> toggleFavorite(String capsuleId) async {
    if (_uid == null) return null;

    final ref = _firestore.collection('users').doc(_uid);
    final isFavorite = _favoriteIds.contains(capsuleId);
    if (isFavorite) {
      _favoriteIds.remove(capsuleId);
      await ref.update({
        'favorites': FieldValue.arrayRemove([capsuleId]),
      });
    } else {
      _favoriteIds.add(capsuleId);
      await ref.update({
        'favorites': FieldValue.arrayUnion([capsuleId]),
      });
    }

    notifyListeners();
  }

  void onLogout() {
    _favoriteIds.clear();
    _uid = null;
    notifyListeners();
  }
}

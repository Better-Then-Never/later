import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CapsuleDataService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, List<Map<String, dynamic>>> _capsuleCache = {};

  Stream<List<Map<String, dynamic>>>? _activeStream;
  Stream<List<Map<String, dynamic>>>? get activeStream => _activeStream;

  bool _isFetched = false;
  bool get isFetched => _isFetched;

  List<Map<String, dynamic>> capsulesFor(String uid) =>
      _capsuleCache[uid] ?? [];

  Future<List<Map<String, dynamic>>> fetchCapsulesByOwner(
    String ownerId,
  ) async {
    if (_capsuleCache.containsKey(ownerId)) {
      return _capsuleCache[ownerId]!;
    }

    try {
      final snap = await _firestore
          .collection('capsules')
          .where('ownerId', isEqualTo: ownerId)
          .orderBy('createdAt', descending: true)
          .get();

      final list = snap.docs.map((d) => _convert(d)).toList();
      _capsuleCache[ownerId] = list;
      _isFetched = true;
      notifyListeners();
      return list;
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToCapsules(String ownerId) {
    return _firestore
        .collection('capsules')
        .where('ownerId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map((d) => _convert(d)).toList();
          _capsuleCache[ownerId] = list;
          notifyListeners();
          return list;
        });
  }

  Map<String, dynamic> _convert(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return {
      'id': doc.id,
      'title': data['title'] ?? 'Untitled',
      'description': data['description'] ?? '',
      'color': data['color'] ?? 'blue',
      'imageUrl': data['imageUrl'],
      'openAt': data['openAt'],
      'createdAt': data['createdAt'],
      'isScheduled': data['isScheduled'] ?? false,
      'privacy': data['privacy'] ?? 'friends',
      'ownerId': data['ownerId'],
      'location': data['location'],
      'sharedWith': (data['sharedWith'] as List<dynamic>?)?.cast<String>(),
    };
  }

  Future<void> deleteCapsules(List<String> capsuleIds) async {
    if (capsuleIds.isEmpty) return;

    final batch = _firestore.batch();

    for (final id in capsuleIds) {
      final docRef = _firestore.collection('capsules').doc(id);
      batch.delete(docRef);
    }

    await batch.commit();
  }

  void onLogout() {
    _capsuleCache.clear();
    _isFetched = false;
    _activeStream = null;
    notifyListeners();
  }
}

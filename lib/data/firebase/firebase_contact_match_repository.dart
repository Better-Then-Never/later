import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/app_failure.dart';
import '../repositories/repositories.dart';

/// `contactMatches/{uid}`: the request (hashes, at most one an hour) and,
/// written by the functions in its place, the people found.
class FirebaseContactMatchRepository implements ContactMatchRepository {
  FirebaseContactMatchRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection('contactMatches').doc(uid);

  @override
  Future<void> requestMatches(String uid, List<String> hashes) async {
    try {
      await _doc(uid).set({
        'hashes': hashes,
        'at': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  @override
  Stream<ContactMatches?> watchMatches(String uid) =>
      _doc(uid).snapshots().map((s) {
        final d = s.data();
        if (d == null || s.metadata.hasPendingWrites) return null;
        return ContactMatches(
          done: d['status'] == 'done',
          matches: [
            for (final id in (d['matches'] as List?) ?? const [])
              if (id is String) id,
          ],
        );
      });
}

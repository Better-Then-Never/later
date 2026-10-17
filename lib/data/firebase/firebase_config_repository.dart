import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/repositories.dart';

/// App-wide configuration documents (read-only for the app).
class FirebaseConfigRepository implements ConfigRepository {
  FirebaseConfigRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<Map<String, Object?>?> limits() async =>
      (await _db.collection('entitlements').doc('limits').get()).data();
}

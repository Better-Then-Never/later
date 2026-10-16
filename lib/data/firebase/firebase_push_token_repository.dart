import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/repositories.dart';
import 'firestore_mappers.dart';

/// Stores FCM tokens in `users/{uid}/fcmTokens/{token}` (one doc per device).
class FirebasePushTokenRepository implements PushTokenRepository {
  FirebasePushTokenRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      _db.collection(FirestorePaths.users).doc(uid);

  @override
  Future<void> saveToken(String uid, String token, String platform) =>
      _user(uid).collection(FirestorePaths.fcmTokens).doc(token).set({
        'token': token,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> deleteToken(String uid, String token) async {
    await _user(uid).collection(FirestorePaths.fcmTokens).doc(token).delete();
    // Older app versions stored a single token on the user document.
    final user = await _user(uid).get();
    if (user.data()?['fcmToken'] == token) {
      await _user(uid).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
    }
  }
}

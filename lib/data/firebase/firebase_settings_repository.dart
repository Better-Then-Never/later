import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_settings.dart';
import '../repositories/repositories.dart';
import 'firestore_mappers.dart';

class FirebaseSettingsRepository implements SettingsRepository {
  FirebaseSettingsRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db
      .collection(FirestorePaths.users)
      .doc(uid)
      .collection(FirestorePaths.settings)
      .doc(FirestorePaths.settingsDoc);

  @override
  Stream<UserSettings> watch(String uid) => _doc(
    uid,
  ).snapshots().map((doc) => FirestoreMappers.userSettings(doc.data()));

  @override
  Future<void> saveNotifications(String uid, NotificationSettings settings) =>
      _doc(uid).set({
        'notifications': FirestoreMappers.notificationSettings(settings),
      }, SetOptions(merge: true));

  @override
  Future<void> setChatMuted(String uid, String chatId, {required bool muted}) =>
      _doc(uid).set({
        'mutedChats': muted
            ? FieldValue.arrayUnion([chatId])
            : FieldValue.arrayRemove([chatId]),
      }, SetOptions(merge: true));
}

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
  Future<void> saveNotifications(
    String uid,
    NotificationSettings settings,
  ) async {
    final all = FirestoreMappers.notificationSettings(settings);
    try {
      await _doc(uid).set({'notifications': all}, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      // Rules deployed before the added categories reject them: keep the
      // switches those rules know (the others stay on in the meantime).
      if (e.code != 'permission-denied') rethrow;
      final known = {
        for (final entry in all.entries)
          if (!FirestoreMappers.notificationKeysAdded.contains(entry.key))
            entry.key: entry.value,
      };
      await _doc(uid).set({'notifications': known}, SetOptions(merge: true));
    }
  }

  @override
  Future<void> savePrivacy(String uid, PrivacySettings privacy) =>
      _doc(uid).set({
        'privacy': FirestoreMappers.privacySettings(privacy),
      }, SetOptions(merge: true));

  @override
  Future<void> saveLanguage(String uid, String languageCode) =>
      _doc(uid).set({'language': languageCode}, SetOptions(merge: true));

  @override
  Future<void> setChatPinned(
    String uid,
    String chatId, {
    required bool pinned,
  }) => _doc(uid).set({
    'pinnedChats': pinned
        ? FieldValue.arrayUnion([chatId])
        : FieldValue.arrayRemove([chatId]),
  }, SetOptions(merge: true));

  @override
  Future<void> setChatMuted(String uid, String chatId, {required bool muted}) =>
      _doc(uid).set({
        'mutedChats': muted
            ? FieldValue.arrayUnion([chatId])
            : FieldValue.arrayRemove([chatId]),
      }, SetOptions(merge: true));
}

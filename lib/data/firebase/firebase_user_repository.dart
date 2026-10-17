import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../models/user_profile.dart';
import '../repositories/repositories.dart';
import 'firestore_mappers.dart';

class FirebaseUserRepository implements UserRepository {
  FirebaseUserRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Firestore allows at most 30 values in a `whereIn` filter.
  static const _whereInLimit = 30;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestorePaths.users);

  DocumentReference<Map<String, dynamic>> _usernameDoc(String username) =>
      _db.collection(FirestorePaths.usernames).doc(username);

  @override
  Stream<UserProfile?> watchProfile(String uid) => _users
      .doc(uid)
      .snapshots()
      .map(
        (doc) => doc.exists
            ? FirestoreMappers.userProfile(doc.id, doc.data())
            : null,
      );

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    return doc.exists ? FirestoreMappers.userProfile(doc.id, doc.data()) : null;
  }

  @override
  Future<Map<String, UserProfile>> getProfiles(Iterable<String> uids) async {
    final ids = uids.toSet().where((id) => id.isNotEmpty).toList();
    final result = <String, UserProfile>{};
    for (var i = 0; i < ids.length; i += _whereInLimit) {
      final chunk = ids.sublist(
        i,
        i + _whereInLimit > ids.length ? ids.length : i + _whereInLimit,
      );
      final snap = await _users
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        result[doc.id] = FirestoreMappers.userProfile(doc.id, doc.data());
      }
    }
    return result;
  }

  @override
  Future<bool> isUsernameTaken(String username) async {
    final reservation = await _usernameDoc(username).get();
    if (reservation.exists) return true;
    // Accounts created before username reservations existed.
    final legacy = await _users
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return legacy.docs.isNotEmpty;
  }

  @override
  Future<void> createProfile({
    required String uid,
    required String name,
    required String username,
  }) async {
    if (await _isTakenByOther(username, uid)) {
      throw ValidationFailure(AppL10n.current.commonUsernameTaken);
    }
    await _db.runTransaction((tx) async {
      final reservation = await tx.get(_usernameDoc(username));
      if (reservation.exists && reservation.data()?['uid'] != uid) {
        throw ValidationFailure(AppL10n.current.commonUsernameTaken);
      }
      tx.set(_usernameDoc(username), {'uid': uid});
      tx.set(_users.doc(uid), {
        'uid': uid,
        'name': name,
        'username': username,
        'friends': <String>[],
        'favorites': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<void> updateName(String uid, String name) async {
    final doc = _users.doc(uid);
    // Keeps the name search in step (only for people found by name).
    final indexed = (await doc.get()).data()?['nameLower'] is String;
    await doc.update({
      'name': name,
      if (indexed) 'nameLower': name.toLowerCase(),
    });
  }

  @override
  Future<void> changeUsername(String uid, String newUsername) async {
    if (await _isTakenByOther(newUsername, uid)) {
      throw ValidationFailure(AppL10n.current.commonUsernameTaken);
    }
    await _db.runTransaction((tx) async {
      final userDoc = await tx.get(_users.doc(uid));
      final reservation = await tx.get(_usernameDoc(newUsername));
      if (reservation.exists && reservation.data()?['uid'] != uid) {
        throw ValidationFailure(AppL10n.current.commonUsernameTaken);
      }
      final oldUsername = userDoc.data()?['username'];
      DocumentSnapshot<Map<String, dynamic>>? oldReservation;
      if (oldUsername is String && oldUsername != newUsername) {
        oldReservation = await tx.get(_usernameDoc(oldUsername));
      }
      tx.set(_usernameDoc(newUsername), {'uid': uid});
      if (oldReservation != null &&
          oldReservation.exists &&
          oldReservation.data()?['uid'] == uid) {
        tx.delete(oldReservation.reference);
      }
      tx.update(_users.doc(uid), {'username': newUsername});
    });
  }

  Future<bool> _isTakenByOther(String username, String uid) async {
    final reservation = await _usernameDoc(username).get();
    if (reservation.exists) return reservation.data()?['uid'] != uid;
    final legacy = await _users
        .where('username', isEqualTo: username)
        .limit(2)
        .get();
    return legacy.docs.any((doc) => doc.id != uid);
  }

  @override
  Future<List<UserProfile>> searchByUsername(
    String prefix, {
    int limit = 20,
  }) async {
    Query<Map<String, dynamic>> query = _users.orderBy('username');
    if (prefix.isNotEmpty) {
      query = query
          .where('username', isGreaterThanOrEqualTo: prefix)
          .where('username', isLessThan: '$prefix\uf8ff');
    }
    final snap = await query.limit(limit).get();
    return snap.docs
        .map((doc) => FirestoreMappers.userProfile(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<void> setFavorite(String uid, String capsuleId, bool favorite) =>
      _users.doc(uid).set({
        'favorites': favorite
            ? FieldValue.arrayUnion([capsuleId])
            : FieldValue.arrayRemove([capsuleId]),
      }, SetOptions(merge: true));

  @override
  Future<void> setShowAchievements(String uid, bool show) =>
      _users.doc(uid).update({'showAchievements': show});

  @override
  Future<void> setAbout(String uid, String about) => _users.doc(uid).update({
    'about': about.isEmpty ? FieldValue.delete() : about,
  });

  @override
  Future<void> setSearchName(String uid, String? lowerCaseName) => _users
      .doc(uid)
      .update({'nameLower': lowerCaseName ?? FieldValue.delete()});

  @override
  Future<List<UserProfile>> searchByName(
    String prefix, {
    int limit = 20,
  }) async {
    if (prefix.isEmpty) return const [];
    final snap = await _users
        .where('nameLower', isGreaterThanOrEqualTo: prefix)
        .where('nameLower', isLessThan: '$prefix\uf8ff')
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => FirestoreMappers.userProfile(doc.id, doc.data()))
        .toList();
  }
}

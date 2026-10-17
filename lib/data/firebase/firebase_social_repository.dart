import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/capsule.dart';
import '../models/social.dart';
import '../repositories/repositories.dart';
import 'firestore_mappers.dart';

class FirebaseSocialRepository implements SocialRepository {
  FirebaseSocialRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _capsule(String id) =>
      _db.collection(FirestorePaths.capsules).doc(id);

  CollectionReference<Map<String, dynamic>> _reactions(String capsuleId) =>
      _capsule(capsuleId).collection(FirestorePaths.reactions);

  CollectionReference<Map<String, dynamic>> _comments(String capsuleId) =>
      _capsule(capsuleId).collection(FirestorePaths.comments);

  @override
  Stream<List<CapsuleReaction>> watchReactions(
    String capsuleId, {
    int limit = 100,
  }) => _reactions(capsuleId)
      .orderBy('updatedAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snap) => [
          for (final d in snap.docs)
            if (FirestoreMappers.reaction(d.id, d.data())
                case final CapsuleReaction r)
              r,
        ],
      );

  @override
  Stream<ReactionType?> watchMyReaction(String capsuleId, String uid) =>
      _reactions(capsuleId)
          .doc(uid)
          .snapshots()
          .map((doc) => ReactionType.parse(doc.data()?['type']));

  @override
  Future<void> setReaction(String capsuleId, String uid, ReactionType? type) {
    final ref = _reactions(capsuleId).doc(uid);
    if (type == null) return ref.delete();
    return ref.set({
      'type': type.name,
      'uid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<CapsuleComment>> watchComments(
    String capsuleId, {
    int limit = 200,
  }) => _comments(capsuleId)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snap) => snap.docs.reversed
            .map((d) => FirestoreMappers.comment(capsuleId, d.id, d.data()))
            .toList(),
      );

  @override
  Future<void> addComment(
    String capsuleId, {
    required String authorId,
    required String text,
    String? replyTo,
  }) => _comments(capsuleId).add(
    FirestoreMappers.newComment(
      authorId: authorId,
      text: text,
      replyTo: replyTo,
    ),
  );

  @override
  Future<void> deleteComment(String capsuleId, String commentId) =>
      _comments(capsuleId).doc(commentId).delete();

  @override
  Future<void> report({
    required String reporterId,
    required ReportTarget target,
    required String targetPath,
    required ReportReason reason,
    String? details,
  }) => _db.collection(FirestorePaths.reports).add({
    'reporterId': reporterId,
    'targetType': target.name,
    'targetPath': targetPath,
    'reason': reason.name,
    if (details != null && details.trim().isNotEmpty)
      'details': details.trim().length > 1000
          ? details.trim().substring(0, 1000)
          : details.trim(),
    'createdAt': FieldValue.serverTimestamp(),
  });

  @override
  Stream<List<UnlockedAchievement>> watchAchievements(String uid) => _db
      .collection(FirestorePaths.users)
      .doc(uid)
      .collection(FirestorePaths.achievements)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => FirestoreMappers.achievement(d.id, d.data()))
            .toList(),
      );

  @override
  Stream<List<Announcement>> watchAnnouncements({int limit = 20}) => _db
      .collection(FirestorePaths.announcements)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => FirestoreMappers.announcement(d.id, d.data()))
            .toList(),
      );
}

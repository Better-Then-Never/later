import 'capsule.dart';

/// Someone's reaction on a capsule (`capsules/{id}/reactions/{uid}`).
class CapsuleReaction {
  const CapsuleReaction({required this.uid, required this.type, this.at});

  final String uid;
  final ReactionType type;
  final DateTime? at;

  @override
  bool operator ==(Object other) =>
      other is CapsuleReaction &&
      other.uid == uid &&
      other.type == type &&
      other.at == at;

  @override
  int get hashCode => Object.hash(uid, type, at);
}

/// A comment on a capsule (`capsules/{id}/comments/{commentId}`): one level
/// of replies, never edited.
class CapsuleComment {
  const CapsuleComment({
    required this.id,
    required this.capsuleId,
    required this.authorId,
    required this.text,
    this.createdAt,
    this.replyTo,
  });

  /// Longest comment the rules accept.
  static const maxLength = 500;

  final String id;
  final String capsuleId;
  final String authorId;
  final String text;

  /// Null while the server timestamp is pending.
  final DateTime? createdAt;

  /// The comment this one answers (always a top-level comment).
  final String? replyTo;

  @override
  bool operator ==(Object other) =>
      other is CapsuleComment &&
      other.id == id &&
      other.capsuleId == capsuleId &&
      other.authorId == authorId &&
      other.text == text &&
      other.createdAt == createdAt &&
      other.replyTo == replyTo;

  @override
  int get hashCode =>
      Object.hash(id, capsuleId, authorId, text, createdAt, replyTo);
}

/// An achievement tier the Cloud Functions unlocked
/// (`users/{uid}/achievements/{id}`).
class UnlockedAchievement {
  const UnlockedAchievement({
    required this.id,
    required this.tier,
    required this.tiers,
    this.value = 0,
    this.unlockedAt,
  });

  final String id;

  /// The highest tier reached, from 0.
  final int tier;

  /// How many tiers the achievement has.
  final int tiers;

  /// The metric when it unlocked.
  final num value;
  final DateTime? unlockedAt;

  @override
  bool operator ==(Object other) =>
      other is UnlockedAchievement &&
      other.id == id &&
      other.tier == tier &&
      other.tiers == tiers &&
      other.value == value &&
      other.unlockedAt == unlockedAt;

  @override
  int get hashCode => Object.hash(id, tier, tiers, value, unlockedAt);
}

/// A message from the Later team (`announcements/{id}`), in up to five
/// languages.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.createdAt,
  });

  final String id;

  /// Language code -> text; English is always present.
  final Map<String, String> title;
  final Map<String, String> body;
  final DateTime? createdAt;

  String titleIn(String language) => title[language] ?? title['en'] ?? '';
  String bodyIn(String language) => body[language] ?? body['en'] ?? '';
}

/// What a report is about (firestore.rules `reports`).
enum ReportTarget { capsule, comment, user, message }

enum ReportReason { spam, abuse, nudity, violence, privacy, other }

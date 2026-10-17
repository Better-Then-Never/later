/// What one account may do: the one place for the app's limits (B7, the
/// `entitlements/limits` extension point). The defaults are today's
/// numbers; the `entitlements/limits` document in Firestore may lower them,
/// never raise them above what the security rules hold. Nothing is sold and
/// nothing new is enforced from here: it is where a plan would change the
/// numbers later (docs/feel/FEATURES_B.md, B7).
class Limits {
  const Limits({
    this.capsulesPerWeek,
    this.loopFrames = maxLoopFrames,
    this.coAuthors = maxCoAuthors,
    this.groupMembers = maxGroupMembers,
    this.pinnedFriends = 3,
  });

  /// Ceilings the rules hold (firestore.rules); the config cannot go above.
  static const maxLoopFrames = 10;
  static const maxCoAuthors = 5;
  static const maxGroupMembers = 20;
  static const maxPinnedFriends = 10;

  /// Capsules a week; null: no limit (there is none today). Read by nothing
  /// yet: a weekly limit would have to live with the daily streak
  /// (FEATURES_B.md, B7).
  final int? capsulesPerWeek;

  /// Frames of a loop capsule.
  final int loopFrames;

  /// Friends who can make a capsule with its owner.
  final int coAuthors;

  /// People in a group chat, the creator included.
  final int groupMembers;

  /// Friends pinned on the profile.
  final int pinnedFriends;

  static const standard = Limits();

  /// From the `entitlements/limits` document; a missing, odd or too large
  /// value keeps its default.
  factory Limits.fromMap(Map<String, Object?>? data) {
    int pick(String key, int fallback, int max) {
      final v = data?[key];
      return v is int && v >= 1 && v <= max ? v : fallback;
    }

    final perWeek = data?['capsulesPerWeek'];
    return Limits(
      capsulesPerWeek: perWeek is int && perWeek >= 1 ? perWeek : null,
      loopFrames: pick('loopFrames', maxLoopFrames, maxLoopFrames),
      coAuthors: pick('coAuthors', maxCoAuthors, maxCoAuthors),
      groupMembers: pick('groupMembers', maxGroupMembers, maxGroupMembers),
      pinnedFriends: pick('pinnedFriends', 3, maxPinnedFriends),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Limits &&
      other.capsulesPerWeek == capsulesPerWeek &&
      other.loopFrames == loopFrames &&
      other.coAuthors == coAuthors &&
      other.groupMembers == groupMembers &&
      other.pinnedFriends == pinnedFriends;

  @override
  int get hashCode => Object.hash(
    capsulesPerWeek,
    loopFrames,
    coAuthors,
    groupMembers,
    pinnedFriends,
  );
}

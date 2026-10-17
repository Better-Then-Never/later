/// Totals the Cloud Functions keep on `users/{uid}.stats`
/// (functions/lib/gamification.js, social.js). Read-only for the app.
class UserStats {
  const UserStats({
    this.capsules = 0,
    this.publicCapsules = 0,
    this.loopCapsules = 0,
    this.places = 0,
    this.distanceKm = 0,
    this.streakCurrent = 0,
    this.streakLongest = 0,
    this.streakLastDay,
    this.reactionsReceived = 0,
    this.commentsWritten = 0,
    this.nightCapsules = 0,
    this.morningCapsules = 0,
  });

  final int capsules;
  final int publicCapsules;
  final int loopCapsules;

  /// Distinct places (about 5 km cells) with a capsule.
  final int places;
  final double distanceKm;
  final int streakCurrent;
  final int streakLongest;

  /// The user's local day (YYYY-MM-DD) the streak was last extended.
  final String? streakLastDay;
  final int reactionsReceived;
  final int commentsWritten;
  final int nightCapsules;
  final int morningCapsules;

  /// The streak as of [now] (local time): it ends when a whole day passed
  /// without a capsule, even before the server notices.
  int streakAt(DateTime now) {
    final last = streakLastDay;
    if (last == null || streakCurrent == 0) return 0;
    final today = _day(now);
    final yesterday = _day(now.subtract(const Duration(days: 1)));
    return last == today || last == yesterday ? streakCurrent : 0;
  }

  /// Whether today already counts for the streak.
  bool extendedToday(DateTime now) => streakLastDay == _day(now);

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is UserStats &&
      other.capsules == capsules &&
      other.publicCapsules == publicCapsules &&
      other.loopCapsules == loopCapsules &&
      other.places == places &&
      other.distanceKm == distanceKm &&
      other.streakCurrent == streakCurrent &&
      other.streakLongest == streakLongest &&
      other.streakLastDay == streakLastDay &&
      other.reactionsReceived == reactionsReceived &&
      other.commentsWritten == commentsWritten &&
      other.nightCapsules == nightCapsules &&
      other.morningCapsules == morningCapsules;

  @override
  int get hashCode => Object.hash(
    capsules,
    publicCapsules,
    loopCapsules,
    places,
    distanceKm,
    streakCurrent,
    streakLongest,
    streakLastDay,
    reactionsReceived,
    commentsWritten,
    nightCapsules,
    morningCapsules,
  );
}

/// Public profile of a user (`users/{uid}`).
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.username,
    this.friends = const [],
    this.favorites = const {},
    this.verified = false,
    this.followerCount = 0,
    this.followingCount = 0,
    this.showAchievements = true,
    this.stats = const UserStats(),
  });

  /// Placeholder used while a profile is loading or when it does not exist,
  /// matching the strings the app showed before ("Unknown"/"unknown").
  const UserProfile.unknown(this.uid)
    : name = 'Unknown',
      username = 'unknown',
      friends = const [],
      favorites = const {},
      verified = false,
      followerCount = 0,
      followingCount = 0,
      showAchievements = true,
      stats = const UserStats();

  final String uid;
  final String name;
  final String username;
  final List<String> friends;
  final Set<String> favorites;

  /// The verified badge, set by the Later team only (tools/admin).
  final bool verified;

  /// Kept by the Cloud Functions; 0 until they first count.
  final int followerCount;
  final int followingCount;

  /// Whether friends may see this user's achievements.
  final bool showAchievements;
  final UserStats stats;

  UserProfile copyWith({
    String? name,
    String? username,
    List<String>? friends,
    Set<String>? favorites,
    bool? showAchievements,
  }) => UserProfile(
    uid: uid,
    name: name ?? this.name,
    username: username ?? this.username,
    friends: friends ?? this.friends,
    favorites: favorites ?? this.favorites,
    verified: verified,
    followerCount: followerCount,
    followingCount: followingCount,
    showAchievements: showAchievements ?? this.showAchievements,
    stats: stats,
  );

  /// First letter used to group friend lists; never throws on empty names.
  String get initial {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '#' : trimmed[0].toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.uid == uid &&
      other.name == name &&
      other.username == username &&
      _listEquals(other.friends, friends) &&
      other.favorites.length == favorites.length &&
      other.favorites.containsAll(favorites) &&
      other.verified == verified &&
      other.followerCount == followerCount &&
      other.followingCount == followingCount &&
      other.showAchievements == showAchievements &&
      other.stats == stats;

  @override
  int get hashCode => Object.hash(
    uid,
    name,
    username,
    friends.length,
    verified,
    followerCount,
    followingCount,
    stats,
  );
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Username rules shared by signup, settings and Google sign-in.
abstract final class Usernames {
  static final _allowed = RegExp(r'^[a-z0-9._-]{3,30}$');

  /// Turns arbitrary text (e.g. an email prefix) into an allowed username.
  static String sanitize(String input) {
    var s = normalize(input).replaceAll(RegExp(r'[^a-z0-9._-]'), '');
    if (s.length > 24) s = s.substring(0, 24);
    if (s.length < 3) s = s.padRight(3, '0');
    return s;
  }

  static String normalize(String input) => input.trim().toLowerCase();

  /// Returns an error message, or null when [normalized] is acceptable.
  static String? validate(String normalized) {
    if (normalized.isEmpty) return 'Please enter a username';
    if (!_allowed.hasMatch(normalized)) {
      return 'Use 3-30 letters, numbers, dots, dashes or underscores';
    }
    return null;
  }
}

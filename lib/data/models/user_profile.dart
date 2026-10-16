/// Public profile of a user (`users/{uid}`).
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.username,
    this.friends = const [],
    this.favorites = const {},
  });

  /// Placeholder used while a profile is loading or when it does not exist,
  /// matching the strings the app showed before ("Unknown"/"unknown").
  const UserProfile.unknown(this.uid)
    : name = 'Unknown',
      username = 'unknown',
      friends = const [],
      favorites = const {};

  final String uid;
  final String name;
  final String username;
  final List<String> friends;
  final Set<String> favorites;

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
      other.favorites.containsAll(favorites);

  @override
  int get hashCode => Object.hash(uid, name, username, friends.length);
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

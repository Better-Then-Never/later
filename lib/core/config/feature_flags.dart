/// Features that are built but can be hidden as a whole (their settings,
/// entry points and notification switches go with them). A feature is only
/// switched on once it is finished and verified; see docs/ux/FEATURES.md.
abstract final class FeatureFlags {
  /// Emoji reactions on capsules.
  static const reactions = true;

  /// Comments (with one level of replies) on capsules.
  static const comments = true;

  /// Achievements on profiles and their pushes.
  static const achievements = true;

  /// Daily streak and its evening reminder.
  static const streaks = true;

  /// Announcements from the Later team (topic pushes).
  static const news = true;

  /// Loop capsules (several frames played as a loop) and their achievement.
  static const loopCapsules = true;

  /// "On this day": the user's capsules from today's date in earlier years,
  /// above My Capsules.
  static const memories = true;

  /// Friend suggestions from the phone's contacts (hashed emails, opt-in on
  /// both sides). Off until checked on a test phone whose contacts may be
  /// read (docs/feel/BLOCKERS.md).
  static const contactSuggestions = false;

  /// The map drawn by MapLibre with OpenFreeMap's tiles instead of Google
  /// Maps (docs/map/DECISION.md; the owner's choice, 19 Oct 2026): the heat,
  /// bubbles and pins as layers of the map itself. A build goes back to
  /// Google Maps with --dart-define=MAP_LIBRE=false.
  static const mapLibre = bool.fromEnvironment('MAP_LIBRE', defaultValue: true);

  /// The map's data credit (docs/map/ATTRIBUTION.md). false (default): a
  /// tiny credit line is always on the map next to the (i) button. true:
  /// the line shows for the first seconds of each session, then only the
  /// (i) button stays (OpenStreetMap's guidelines allow it collapsing).
  static const mapCreditCollapses = false;
}

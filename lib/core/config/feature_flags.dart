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

  /// The map's data credit (docs/map/ATTRIBUTION.md). true (the owner's
  /// choice, 19 Oct 2026): the tiny credit line shows next to the (i) at the
  /// start of each session, until the map is first touched (at most 5 s),
  /// then only the (i) stays (OpenStreetMap's guidelines allow it
  /// collapsing). false: the line is always on the map.
  static const mapCreditCollapses = true;

  /// The map reads only the friends' and public capsules that changed since
  /// the pins it kept on the phone (docs/map/COLD_START.md, "Delta sync"),
  /// not all of them at every start. Off until the backend it needs is
  /// deployed (the deletion records, their rules, two indexes and a TTL
  /// policy); without it the map would notice and read everything anyway.
  /// --dart-define=MAP_DELTA=true for the local emulators.
  static const mapDeltaSync = bool.fromEnvironment('MAP_DELTA');
}

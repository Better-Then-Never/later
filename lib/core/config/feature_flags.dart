/// Features that are built but can be hidden as a whole (their settings,
/// entry points and notification switches go with them). A feature is only
/// switched on once it is finished and verified; see docs/ux/FEATURES.md.
abstract final class FeatureFlags {
  /// Emoji reactions on capsules.
  static const reactions = false;

  /// Comments (with one level of replies) on capsules.
  static const comments = false;

  /// Achievements on profiles and their pushes.
  static const achievements = false;

  /// Daily streak and its evening reminder.
  static const streaks = false;

  /// Announcements from the Later team (topic pushes).
  static const news = false;
}

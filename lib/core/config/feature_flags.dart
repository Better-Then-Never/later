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
  static const loopCapsules = false;
}

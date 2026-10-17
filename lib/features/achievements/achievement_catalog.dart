import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/config/feature_flags.dart';
import '../../core/l10n/l10n.dart';
import '../../data/models/user_profile.dart';

/// One achievement of the registry. Mirrors ACHIEVEMENTS in
/// functions/lib/gamification.js (ids, metrics and tiers must match; the
/// server unlocks, the app only shows).
class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.tiers,
    required this.icon,
    required this.metric,
    required this.title,
    required this.goal,
  });

  final String id;

  /// Thresholds of the levels, lowest first.
  final List<num> tiers;
  final IconData icon;

  /// The user's current value for this achievement.
  final num Function(UserProfile profile) metric;
  final String Function(AppLocalizations l10n) title;

  /// What the given threshold asks for ("Create 25 capsules").
  final String Function(AppLocalizations l10n, num threshold) goal;

  /// The highest level reached for [value], from 0; -1 for none.
  int tierFor(num value) {
    var reached = -1;
    for (var i = 0; i < tiers.length; i++) {
      if (value >= tiers[i]) reached = i;
    }
    return reached;
  }
}

abstract final class AchievementCatalog {
  static int _i(num n) => n.toInt();

  static final all = <AchievementDef>[
    AchievementDef(
      id: 'first_capsule',
      tiers: const [1],
      icon: Icons.photo_camera,
      metric: (p) => p.stats.capsules,
      title: (l) => l.achievementFirstCapsule,
      goal: (l, _) => l.achievementFirstCapsuleGoal,
    ),
    AchievementDef(
      id: 'collector',
      tiers: const [5, 25, 100, 500],
      icon: Icons.collections,
      metric: (p) => p.stats.capsules,
      title: (l) => l.achievementCollector,
      goal: (l, t) => l.achievementCollectorGoal(_i(t)),
    ),
    AchievementDef(
      id: 'open_book',
      tiers: const [1, 10, 50],
      icon: Icons.public,
      metric: (p) => p.stats.publicCapsules,
      title: (l) => l.achievementOpenBook,
      goal: (l, t) => l.achievementOpenBookGoal(_i(t)),
    ),
    AchievementDef(
      id: 'animator',
      tiers: const [1, 10],
      icon: Icons.animation,
      metric: (p) => p.stats.loopCapsules,
      title: (l) => l.achievementAnimator,
      goal: (l, t) => l.achievementAnimatorGoal(_i(t)),
    ),
    AchievementDef(
      id: 'streak',
      tiers: const [3, 7, 14, 30, 100],
      icon: Icons.local_fire_department,
      metric: (p) => p.stats.streakLongest,
      title: (l) => l.achievementStreak,
      goal: (l, t) => l.achievementStreakGoal(_i(t)),
    ),
    AchievementDef(
      id: 'explorer',
      tiers: const [3, 10, 25, 100],
      icon: Icons.explore,
      metric: (p) => p.stats.places,
      title: (l) => l.achievementExplorer,
      goal: (l, t) => l.achievementExplorerGoal(_i(t)),
    ),
    AchievementDef(
      id: 'traveler',
      tiers: const [100, 1000, 10000],
      icon: Icons.flight_takeoff,
      metric: (p) => p.stats.distanceKm,
      title: (l) => l.achievementTraveler,
      goal: (l, t) => l.achievementTravelerGoal(
        NumberFormat.decimalPattern(l.localeName).format(t),
      ),
    ),
    AchievementDef(
      id: 'crowd_pleaser',
      tiers: const [10, 100, 1000],
      icon: Icons.favorite,
      metric: (p) => p.stats.reactionsReceived,
      title: (l) => l.achievementCrowdPleaser,
      goal: (l, t) => l.achievementCrowdPleaserGoal(_i(t)),
    ),
    AchievementDef(
      id: 'chatterbox',
      tiers: const [1, 25, 100],
      icon: Icons.chat_bubble,
      metric: (p) => p.stats.commentsWritten,
      title: (l) => l.achievementChatterbox,
      goal: (l, t) => l.achievementChatterboxGoal(_i(t)),
    ),
    AchievementDef(
      id: 'friendly',
      tiers: const [1, 10, 50],
      icon: Icons.group,
      metric: (p) => p.friends.length,
      title: (l) => l.achievementFriendly,
      goal: (l, t) => l.achievementFriendlyGoal(_i(t)),
    ),
    AchievementDef(
      id: 'night_owl',
      tiers: const [1, 10],
      icon: Icons.nightlight,
      metric: (p) => p.stats.nightCapsules,
      title: (l) => l.achievementNightOwl,
      goal: (l, t) => l.achievementNightOwlGoal(_i(t)),
    ),
    AchievementDef(
      id: 'early_bird',
      tiers: const [1, 10],
      icon: Icons.wb_twilight,
      metric: (p) => p.stats.morningCapsules,
      title: (l) => l.achievementEarlyBird,
      goal: (l, t) => l.achievementEarlyBirdGoal(_i(t)),
    ),
    AchievementDef(
      id: 'curious',
      tiers: const [10, 50, 250, 1000],
      icon: Icons.visibility,
      metric: (p) => p.stats.capsulesViewed,
      title: (l) => l.achievementCurious,
      goal: (l, t) => l.achievementCuriousGoal(_i(t)),
    ),
  ];

  /// What the app shows: achievements of features that are switched on.
  static List<AchievementDef> get visible => [
    for (final a in all)
      if (a.id != 'animator' || FeatureFlags.loopCapsules) a,
  ];

  static AchievementDef? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}

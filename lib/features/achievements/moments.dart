import 'dart:async';
import 'dart:convert';

import '../../app/session/session_controller.dart';
import '../../core/config/feature_flags.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/social.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/preferences_store.dart';
import 'achievement_catalog.dart';

/// Something worth celebrating while the app runs (B7).
sealed class Moment {
  const Moment();
}

/// The server unlocked [tier] of [def] (and [more] other levels with it).
class AchievementMoment extends Moment {
  const AchievementMoment(this.def, this.tier, {this.more = 0});

  final AchievementDef def;
  final int tier;
  final int more;
}

/// The streak reached [days], one of [MomentsController.streakMilestones].
class StreakMoment extends Moment {
  const StreakMoment(this.days);

  final int days;
}

/// Turns real events into moments: an achievement level the server just
/// unlocked (the user's `achievements` documents) and a streak reaching a
/// milestone (their stats). What was celebrated is kept per account on this
/// phone, so nothing shows twice; on an account's first start here the
/// levels it already has are taken as seen (no flood of old news). Levels
/// unlocked while the app was closed are celebrated on the next start.
class MomentsController {
  MomentsController({
    required SessionController session,
    required SocialRepository social,
    required PreferencesStore prefs,
    required void Function(Moment moment) show,
    DateTime Function()? now,
  }) : _session = session,
       _social = social,
       _prefs = prefs,
       _show = show,
       _now = now ?? DateTime.now;

  static const streakMilestones = [3, 7, 14, 30, 50, 100, 200, 365];

  final SessionController _session;
  final SocialRepository _social;
  final PreferencesStore _prefs;
  final void Function(Moment) _show;
  final DateTime Function() _now;

  String? _uid;
  StreamSubscription<List<UnlockedAchievement>>? _sub;
  bool _loaded = false;

  /// Level per achievement already celebrated (or found on the first start).
  Map<String, int>? _seen;

  /// "day:days" of the last streak looked at.
  String? _streakSeen;

  void start() {
    _session.addListener(_sessionChanged);
    _sessionChanged();
  }

  // Cancels without waiting: awaiting a subscription's cancel in a widget
  // test resumes outside the test's fake time and stalls it.
  void dispose() {
    _session.removeListener(_sessionChanged);
    unawaited(_sub?.cancel());
    _sub = null;
  }

  void _sessionChanged() {
    final uid = _session.uid;
    if (uid != _uid) {
      unawaited(_switchTo(uid));
      return;
    }
    _checkStreak();
  }

  Future<void> _switchTo(String? uid) async {
    unawaited(_sub?.cancel());
    _sub = null;
    _uid = uid;
    _loaded = false;
    _seen = null;
    _streakSeen = null;
    if (uid == null) return;
    final seen = await _prefs.string(uid, 'moments_achievements');
    final streak = await _prefs.string(uid, 'moments_streak');
    if (_uid != uid) return; // signed out or switched meanwhile
    _seen = _decode(seen);
    _streakSeen = streak;
    _loaded = true;
    if (FeatureFlags.achievements) {
      _sub = _social
          .watchAchievements(uid)
          .listen(
            (list) => _onAchievements(uid, list),
            onError: (Object e) =>
                AppLogger.warning('Achievements for moments failed', error: e),
          );
    }
    _checkStreak();
  }

  static Map<String, int>? _decode(String? value) {
    if (value == null) return null;
    try {
      final map = jsonDecode(value);
      if (map is! Map) return null;
      return {
        for (final e in map.entries)
          if (e.key is String && e.value is int)
            e.key as String: e.value as int,
      };
    } catch (_) {
      return null;
    }
  }

  void _onAchievements(String uid, List<UnlockedAchievement> list) {
    if (_uid != uid) return;
    final seen = _seen;
    final fresh = <(UnlockedAchievement, AchievementDef)>[];
    for (final a in list) {
      final def = AchievementCatalog.byId(a.id);
      if (def == null || !AchievementCatalog.visible.contains(def)) continue;
      if (seen != null && a.tier > (seen[a.id] ?? -1)) fresh.add((a, def));
    }
    final next = {...?seen};
    for (final a in list) {
      if (a.tier > (next[a.id] ?? -1)) next[a.id] = a.tier;
    }
    _seen = next;
    unawaited(_prefs.setString(uid, 'moments_achievements', jsonEncode(next)));
    if (fresh.isEmpty) return;
    // The newest first; the others are counted.
    fresh.sort(
      (a, b) => (b.$1.unlockedAt ?? DateTime(0)).compareTo(
        a.$1.unlockedAt ?? DateTime(0),
      ),
    );
    final (newest, def) = fresh.first;
    _show(AchievementMoment(def, newest.tier, more: fresh.length - 1));
  }

  void _checkStreak() {
    final uid = _uid;
    final profile = _session.profile;
    if (!_loaded || !FeatureFlags.streaks || uid == null) return;
    if (profile == null || profile.uid != uid) return;
    final stats = profile.stats;
    if (!stats.extendedToday(_now())) return;
    final key = '${stats.streakLastDay}:${stats.streakCurrent}';
    if (_streakSeen == key) return;
    _streakSeen = key;
    unawaited(_prefs.setString(uid, 'moments_streak', key));
    if (streakMilestones.contains(stats.streakCurrent)) {
      _show(StreakMoment(stats.streakCurrent));
    }
  }
}

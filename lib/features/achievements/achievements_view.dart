import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/feature_flags.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/social.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/styles/box_decorations.dart';
import '../../shared/widgets/buttons/go_back_button.dart';
import '../../shared/widgets/page_header.dart';
import 'achievement_catalog.dart';
import 'achievement_icon.dart';

/// An achievement as one user stands with it: the level the server
/// unlocked or the stats already reach (whichever is higher), and the next
/// goal.
class AchievementStanding {
  const AchievementStanding(this.def, this.tier, this.value);

  final AchievementDef def;
  final int tier;
  final num value;

  bool get unlocked => tier >= 0;
  bool get complete => tier >= def.tiers.length - 1;

  /// The threshold of the next level (null when complete).
  num? get nextGoal => complete ? null : def.tiers[tier + 1];

  static List<AchievementStanding> of(
    UserProfile profile,
    List<UnlockedAchievement> unlocked,
  ) {
    final byId = {for (final u in unlocked) u.id: u};
    return [
      for (final def in AchievementCatalog.visible)
        () {
          final value = def.metric(profile);
          final server = byId[def.id]?.tier ?? -1;
          final tier = server > def.tierFor(value)
              ? server.clamp(-1, def.tiers.length - 1)
              : def.tierFor(value);
          return AchievementStanding(def, tier, value);
        }(),
    ];
  }
}

/// Streams the standings of [profile]'s owner.
class AchievementsBuilder extends StatelessWidget {
  const AchievementsBuilder({
    super.key,
    required this.profile,
    required this.builder,
  });

  final UserProfile profile;
  final Widget Function(BuildContext, List<AchievementStanding>) builder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UnlockedAchievement>>(
      stream: context.read<SocialRepository>().watchAchievements(profile.uid),
      builder: (context, snap) => builder(
        context,
        AchievementStanding.of(profile, snap.data ?? const []),
      ),
    );
  }
}

/// The profile card: the streak and the unlocked badges, highest first.
class AchievementsPanel extends StatelessWidget {
  const AchievementsPanel({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final streak = profile.stats.streakAt(DateTime.now());
    return AchievementsBuilder(
      profile: profile,
      builder: (context, standings) {
        final unlocked = standings.where((s) => s.unlocked).toList()
          ..sort((a, b) => b.tier.compareTo(a.tier));
        return InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AchievementsPage(profile: profile),
            ),
          ),
          child: Ink(
            decoration: BoxDecorations.whiteCard(context, borderRadius: 25),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.achievementsTitle,
                        style: TextStyle(
                          fontFamily: kAppFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      l10n.achievementsSeeAll,
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (FeatureFlags.streaks && streak > 0) ...[
                  const SizedBox(height: 8),
                  StreakChip(profile: profile),
                ],
                const SizedBox(height: 10),
                if (unlocked.isEmpty)
                  Text(
                    l10n.achievementsNoneYet,
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      color: palette.textSecondary,
                    ),
                  )
                else
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: unlocked.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => Tooltip(
                        message: unlocked[i].def.title(l10n),
                        child: AchievementIcon(
                          icon: unlocked[i].def.icon,
                          tier: unlocked[i].tier,
                          tiers: unlocked[i].def.tiers.length,
                          size: 52,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// "🔥 4-day streak", and whether today already counts.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final streak = profile.stats.streakAt(now);
    final today = profile.stats.extendedToday(now);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warningOrange.withValues(alpha: 0.15),
        borderRadius: AppRadii.lCircular,
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '🔥 ${l10n.achievementsStreakDays(streak)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text:
                  '  ·  ${today ? l10n.achievementsStreakTodayDone : l10n.achievementsStreakKeep}',
            ),
          ],
        ),
        style: TextStyle(
          fontFamily: kAppFontFamily,
          fontSize: 13,
          color: context.palette.textPrimary,
        ),
      ),
    );
  }
}

/// Every achievement with its level and the next goal.
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.backgroundAlt,
      body: Column(
        children: [
          PageHeader(
            mainText: l10n.achievementsTitle,
            description: l10n.achievementsDescription,
            leadingButton: GoBackButton(context: context),
          ),
          Expanded(
            child: AchievementsBuilder(
              profile: profile,
              builder: (context, standings) => ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                itemCount: standings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    _AchievementRow(standing: standings[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.standing});

  final AchievementStanding standing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final def = standing.def;
    final next = standing.nextGoal;
    final floor = standing.tier < 0 ? 0 : def.tiers[standing.tier];
    final progress = next == null
        ? 1.0
        : ((standing.value - floor) / (next - floor)).clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecorations.whiteCard(context, borderRadius: 20),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          AchievementIcon(
            icon: def.icon,
            tier: standing.tier,
            tiers: def.tiers.length,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.title(l10n),
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                Text(
                  standing.unlocked
                      ? l10n.achievementsTier(
                          standing.tier + 1,
                          def.tiers.length,
                        )
                      : l10n.achievementsLocked,
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 12,
                    color: palette.textMuted,
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    def.goal(l10n, next),
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.toDouble(),
                      minHeight: 6,
                      backgroundColor: palette.surfaceMuted,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

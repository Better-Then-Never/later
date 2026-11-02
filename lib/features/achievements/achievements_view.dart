import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_page_route.dart';
import '../../app/session/session_controller.dart';
import '../../core/assets/app_assets.dart';
import '../../core/config/feature_flags.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/social.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/v2/card_v2.dart';
import '../streak/streak_page.dart';
import 'achievement_catalog.dart';
import 'achievement_mark.dart';
import 'achievement_sheet.dart';
import 'streak_flame.dart';

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

  /// Something done toward it already.
  bool get started => unlocked || value > 0;

  /// How far along the next level is, from 0 to 1 ("16 of 20" is 0.8);
  /// 1 when complete.
  double get progress {
    final next = nextGoal;
    if (next == null) return 1;
    return (value / next).clamp(0.0, 1.0).toDouble();
  }

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

/// The profile's achievements card (Profile v4, Figma 7182:4354): the
/// streak, five marks (earned ones first, then the closest to earning) and
/// "All achievements · 7 of 13".
class AchievementsPanel extends StatelessWidget {
  const AchievementsPanel({super.key, required this.profile});

  final UserProfile profile;

  /// Marks shown on the card.
  static const marks = 5;

  /// The marks to show: earned first (highest level first), then the ones
  /// with the most progress.
  static List<AchievementStanding> pick(List<AchievementStanding> all) {
    final sorted = [...all]
      ..sort((a, b) {
        if (a.unlocked != b.unlocked) return a.unlocked ? -1 : 1;
        if (a.tier != b.tier) return b.tier.compareTo(a.tier);
        return b.progress.compareTo(a.progress);
      });
    return sorted.take(marks).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final now = DateTime.now();
    final streak = profile.stats.streakAt(now);
    final today = profile.stats.extendedToday(now);
    final own = context.select<SessionController?, bool>(
      (s) => s?.uid == profile.uid,
    );
    void openAll() => Navigator.of(
      context,
    ).push(appRoute<void>(AchievementsPage(profile: profile)));
    Widget divider() =>
        Divider(height: 1, thickness: 1, indent: 16, color: palette.divider);
    return AchievementsBuilder(
      profile: profile,
      builder: (context, standings) {
        final earned = standings.where((s) => s.unlocked).length;
        return CardV2(
          child: Column(
            children: [
              if (FeatureFlags.streaks && (own || streak > 0)) ...[
                RowV2(
                  leading: SizedBox.square(
                    dimension: 28,
                    child: Center(child: StreakFlame(size: 22, greyed: !today)),
                  ),
                  title: streak > 0
                      ? l10n.achievementsStreakDays(streak)
                      : l10n.streakNoneTitle,
                  subtitle: streak == 0
                      ? l10n.streakStartToday
                      : today
                      ? l10n.achievementsStreakTodayDone
                      : l10n.achievementsStreakKeep,
                  onTap: own ? () => StreakPage.open(context) : null,
                ),
                divider(),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final s in pick(standings))
                      Tooltip(
                        message: s.def.title(l10n),
                        child: GestureDetector(
                          onTap: () => AchievementSheet.show(
                            context,
                            s,
                            passportUid: own ? profile.uid : null,
                          ),
                          child: AchievementMark(standing: s, size: 46),
                        ),
                      ),
                  ],
                ),
              ),
              divider(),
              RowV2(
                title: l10n.profileAllAchievements,
                subtitle: earned == 0 ? l10n.achievementsNoneYet : null,
                value: l10n.achievementsCount(earned, standings.length),
                onTap: openAll,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "🔥 4-day streak", and whether today already counts. At risk (today not
/// counted yet) the flame is grey and the chip has an orange ring.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final streak = profile.stats.streakAt(now);
    final today = profile.stats.extendedToday(now);
    final own = context.select<SessionController?, bool>(
      (s) => s?.uid == profile.uid,
    );
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.warningOrange.withValues(alpha: 0.15),
        borderRadius: AppRadii.lCircular,
        border: today
            ? null
            : Border.all(color: AppColors.warningOrange, width: 1.5),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: StreakFlame(size: 13, greyed: !today),
            ),
            TextSpan(
              text: ' ${l10n.achievementsStreakDays(streak)}',
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
    if (!own) return chip;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => StreakPage.open(context),
        child: chip,
      ),
    );
  }
}

/// Every achievement of the catalogue (Figma page 14, `7191:1084`): the
/// streak on top (the signed-in user's own page), how many are earned, then
/// the marks in their groups. A mark opens its sheet.
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key, required this.profile});

  /// Whose achievements: the signed-in user's or a friend's.
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    // Your own page follows the live stats (a capsule just made counts).
    final own = context.select<SessionController?, UserProfile?>(
      (s) => s?.uid == profile.uid ? (s?.profile ?? profile) : null,
    );
    final shown = own ?? profile;
    return Scaffold(
      backgroundColor: palette.backgroundAlt,
      body: Column(
        children: [
          PageHeaderV2(
            title: l10n.achievementsTitle,
            backLabel: l10n.commonBack,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: AchievementsBuilder(
              profile: shown,
              builder: (context, standings) => ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  24 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: [
                  if (own != null && FeatureFlags.streaks) ...[
                    _StreakRow(stats: own.stats),
                    const SizedBox(height: 12),
                  ],
                  AchievementsGrid(standings: standings, passportUid: own?.uid),
                  const SizedBox(height: 12),
                  Text(
                    l10n.achievementsDescription,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "3 of 13", then a card of marks per group (Capsules, Habits, Places,
/// Friends), three to a row.
class AchievementsGrid extends StatelessWidget {
  const AchievementsGrid({
    super.key,
    required this.standings,
    this.passportUid,
  });

  final List<AchievementStanding> standings;

  /// Passed on to a mark's sheet (its Passport button).
  final String? passportUid;

  static String groupName(AppLocalizations l10n, AchievementGroup group) =>
      switch (group) {
        AchievementGroup.capsules => l10n.achievementsGroupCapsules,
        AchievementGroup.habits => l10n.achievementsGroupHabits,
        AchievementGroup.places => l10n.achievementsGroupPlaces,
        AchievementGroup.friends => l10n.achievementsGroupFriends,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final earned = standings.where((s) => s.unlocked).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            l10n.achievementsCount(earned, standings.length),
            textAlign: TextAlign.end,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              color: context.palette.textSecondary,
            ),
          ),
        ),
        for (final group in AchievementGroup.values)
          if (standings.where((s) => s.def.group == group).toList()
              case final members when members.isNotEmpty) ...[
            GroupLabelV2(groupName(l10n, group)),
            CardV2(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  for (var i = 0; i < members.length; i += 3)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var j = i; j < i + 3; j++)
                          Expanded(
                            child: j < members.length
                                ? AchievementTile(
                                    standing: members[j],
                                    onTap: () => AchievementSheet.show(
                                      context,
                                      members[j],
                                      passportUid: passportUid,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

/// The streak on top of the page: the flame, the days, what today needs.
/// Opens the Streak page.
class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final now = DateTime.now();
    final days = stats.streakAt(now);
    final today = stats.extendedToday(now);
    final title = days > 0
        ? l10n.achievementsStreakDays(days)
        : l10n.streakNoneTitle;
    final line = today
        ? l10n.achievementsStreakTodayDone
        : days > 0
        ? l10n.achievementsStreakKeep
        : l10n.streakStartToday;
    return CardV2(
      child: Semantics(
        button: true,
        label: '$title. $line',
        excludeSemantics: true,
        child: InkWell(
          onTap: () => StreakPage.open(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
            child: Row(
              children: [
                StreakFlame(size: 28, greyed: !today),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 18,
                          height: 1.2,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        line,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          height: 1.25,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Image.asset(AppIcons.goHere, width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

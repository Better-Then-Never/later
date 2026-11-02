import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/router/app_page_route.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_sheets.dart';
import '../../shared/widgets/pill_v2.dart';
import '../world/world_page.dart';
import 'achievement_catalog.dart';
import 'achievement_mark.dart';
import 'achievements_view.dart';

/// One achievement (Figma page 14, `7191:1169`): the mark large, what it
/// asks, how far along it is ("16 of 20 · 4 to go"), and for a places one
/// the way to the Passport. The drawing's "friends who have it" is left
/// out: the app knows no one's achievements but the profile it shows.
class AchievementSheet extends StatelessWidget {
  const AchievementSheet({super.key, required this.standing, this.passportUid});

  final AchievementStanding standing;

  /// Whose Passport the places button opens; null: no button (a friend's
  /// achievements).
  final String? passportUid;

  static Future<void> show(
    BuildContext context,
    AchievementStanding standing, {
    String? passportUid,
  }) => showEdgeSheet<void>(
    context,
    (_) => AchievementSheet(standing: standing, passportUid: passportUid),
  );

  /// "16 of 20 · 4 to go" toward [goal], numbers in the app's language.
  static String progressText(AppLocalizations l10n, num value, num goal) {
    final format = NumberFormat.decimalPattern(l10n.localeName);
    final have = value.floor().clamp(0, goal);
    return l10n.achievementsProgressOf(
      format.format(have),
      format.format(goal),
      format.format(goal - have),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final def = standing.def;
    final next = standing.nextGoal;
    final tiers = def.tiers.length;
    final passport = passportUid;
    final level = !standing.unlocked
        ? null
        : standing.complete
        ? (tiers > 1
              ? l10n.achievementsAllLevels(tiers)
              : l10n.achievementsDone)
        : l10n.achievementsTier(standing.tier + 1, tiers);
    final bodyStyle = AppTextStyles.body.copyWith(
      fontSize: 15,
      height: 1.3,
      color: palette.textSecondary,
    );
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle.v2(),
              const SizedBox(height: 12),
              AchievementMark(standing: standing, size: 120),
              const SizedBox(height: 16),
              Text(
                def.title(l10n),
                textAlign: TextAlign.center,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 24,
                  height: 1.2,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                def.goal(l10n, next ?? def.tiers.last),
                textAlign: TextAlign.center,
                style: bodyStyle,
              ),
              if (level != null) ...[
                const SizedBox(height: 2),
                Text(
                  level,
                  textAlign: TextAlign.center,
                  style: bodyStyle.copyWith(
                    fontSize: 13,
                    color: standing.complete
                        ? palette.accentText
                        : palette.textMuted,
                  ),
                ),
              ],
              if (next != null) ...[
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  // Fills from empty when the sheet opens.
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: (standing.value / next).clamp(0.0, 1.0).toDouble(),
                    ),
                    duration: AppMotion.of(context, AppMotion.reveal),
                    curve: AppMotion.enter,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor: palette.divider,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  progressText(l10n, standing.value, next),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
              ],
              if (passport != null && def.group == AchievementGroup.places) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: PillV2(
                    label: l10n.achievementsSeePassport,
                    kind: PillV2Kind.outline,
                    onTap: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      navigator.push(appRoute<void>(WorldPage(uid: passport)));
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

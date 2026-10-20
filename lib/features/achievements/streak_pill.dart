import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_routes.dart';
import '../../app/session/session_controller.dart';
import '../../core/config/feature_flags.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/user_profile.dart';
import '../../shared/motion/app_motion_widgets.dart';
import '../../shared/widgets/app_sheets.dart';
import '../../shared/widgets/buttons/default_green_button.dart';
import 'streak_flame.dart';

/// The streak on the map (B7): the flame and the days, as tall as the map's
/// round buttons. At risk (today not counted yet) the flame is grey and the
/// pill has an orange ring; when a capsule counts, the colour comes back and
/// the flame swells. Hidden without a streak. A tap explains it.
class StreakPill extends StatelessWidget {
  const StreakPill({super.key, this.height = AppSizes.mapControl});

  final double height;

  @override
  Widget build(BuildContext context) {
    final stats = context.select<SessionController, UserStats?>(
      (s) => s.profile?.stats,
    );
    if (!FeatureFlags.streaks || stats == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final days = stats.streakAt(now);
    if (days == 0) return const SizedBox.shrink();
    final atRisk = stats.atRisk(now);
    final palette = context.palette;
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: atRisk
          ? '${l10n.achievementsStreakDays(days)}. ${l10n.achievementsStreakKeep}'
          : '${l10n.achievementsStreakDays(days)}. ${l10n.achievementsStreakTodayDone}',
      excludeSemantics: true,
      child: AppPressable(
        child: GestureDetector(
          onTap: () => StreakCard.show(context),
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(height / 2),
              border: atRisk
                  ? Border.all(color: AppColors.warningOrange, width: 2)
                  : palette.isDark
                  ? Border.all(color: palette.cardBorder)
                  : null,
              boxShadow: AppShadows.raised(context),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A new key when the streak grows or is saved: it swells.
                StreakFlame(
                  key: ValueKey('$days-$atRisk'),
                  size: 17,
                  greyed: atRisk,
                ),
                const SizedBox(width: 5),
                Text(
                  '$days',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: atRisk ? palette.textSecondary : palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// What the streak is and where it stands: the days, whether today counts,
/// the longest one; at risk, a way to the camera.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key});

  static Future<void> show(BuildContext context) =>
      showCenteredSheet<void>(context, const StreakCard());

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final stats =
        context.select<SessionController, UserStats?>(
          (s) => s.profile?.stats,
        ) ??
        const UserStats();
    final now = DateTime.now();
    final days = stats.streakAt(now);
    final atRisk = stats.atRisk(now);
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSheets.radius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StreakFlame(size: 44, greyed: atRisk),
          const SizedBox(height: 8),
          Text(
            l10n.achievementsStreakDays(days),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            atRisk ? l10n.streakAtRisk : l10n.streakSafe,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 15,
              color: atRisk ? AppColors.warningOrange : palette.textSecondary,
            ),
          ),
          if (stats.streakLongest > days) ...[
            const SizedBox(height: 6),
            Text(
              l10n.streakLongest(stats.streakLongest),
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 13,
                color: palette.textMuted,
              ),
            ),
          ],
          if (atRisk) ...[
            const SizedBox(height: 16),
            DefaultGreenButton(
              text: l10n.streakMakeCapsule,
              width: 220,
              height: 48,
              textFontSize: 17,
              onTap: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                unawaited(AppRoutes.toCamera(navigator.context));
              },
            ),
          ],
        ],
      ),
    );
  }
}

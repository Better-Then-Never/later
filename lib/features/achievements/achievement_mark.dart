import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import 'achievement_icon.dart';
import 'achievements_view.dart';

/// An achievement on the Achievements page (Figma page 14, `7191:1084`): a
/// ring of the progress to the next level around its symbol. Earned (a
/// level reached) the inside is filled green and the symbol is white;
/// otherwise the symbol sits on a grey plate, greyed until it starts.
class AchievementMark extends StatelessWidget {
  const AchievementMark({super.key, required this.standing, this.size = 72});

  final AchievementStanding standing;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final def = standing.def;
    final earned = standing.unlocked;
    final art = AchievementIcon.artFor(def.id);
    final stroke = size * 0.075;
    final symbolColor = earned
        ? AppColors.onAccent
        : standing.started
        ? palette.icon
        : palette.iconMuted;
    final Widget symbol = art == null
        ? Icon(def.icon, size: size * 0.36, color: symbolColor)
        : Padding(
            padding: EdgeInsets.all(size * 0.2),
            child: Image.asset(
              art,
              color: standing.started ? null : palette.iconMuted,
              colorBlendMode: standing.started ? null : BlendMode.srcIn,
            ),
          );
    return SizedBox.square(
      dimension: size,
      // The ring fills from empty when the mark appears.
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: standing.progress),
        duration: AppMotion.of(context, AppMotion.reveal),
        curve: AppMotion.enter,
        builder: (context, value, child) => CustomPaint(
          painter: ProgressRingPainter(
            progress: value,
            stroke: stroke,
            track: palette.divider,
            color: AppColors.brandGreen,
          ),
          child: child,
        ),
        child: Padding(
          padding: EdgeInsets.all(stroke * 2),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned ? AppColors.brandGreen : palette.surfaceMuted,
            ),
            child: Center(child: symbol),
          ),
        ),
      ),
    );
  }
}

/// A round progress ring: the [track] all around, [color] clockwise from
/// the top for [progress] (0 to 1).
class ProgressRingPainter extends CustomPainter {
  const ProgressRingPainter({
    required this.progress,
    required this.stroke,
    required this.track,
    required this.color,
  });

  final double progress;
  final double stroke;
  final Color track;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawArc(rect, 0, 2 * math.pi, false, paint);
    final p = progress.clamp(0.0, 1.0);
    if (p <= 0) return;
    paint
      ..color = color
      ..strokeCap = p >= 1 ? StrokeCap.butt : StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * p, false, paint);
  }

  @override
  bool shouldRepaint(ProgressRingPainter old) =>
      old.progress != progress ||
      old.stroke != stroke ||
      old.track != track ||
      old.color != color;
}

/// A mark with its name and where it stands, for the page's grid: "Done",
/// "Level 2 · 40 %", "40 %" or "Not started".
class AchievementTile extends StatelessWidget {
  const AchievementTile({super.key, required this.standing, this.onTap});

  final AchievementStanding standing;
  final VoidCallback? onTap;

  /// The words under a mark.
  static String status(AppLocalizations l10n, AchievementStanding s) {
    if (s.complete) return l10n.achievementsDone;
    if (!s.started) return l10n.achievementsNotStarted;
    final percent = (s.progress * 100).floor();
    return s.unlocked
        ? l10n.achievementsLevelPercent(s.tier + 1, percent)
        : l10n.achievementsPercent(percent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final name = standing.def.title(l10n);
    final words = status(l10n, standing);
    return Semantics(
      button: onTap != null,
      label: '$name, $words',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
          child: Column(
            children: [
              AchievementMark(standing: standing),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  height: 1.2,
                  fontWeight: standing.unlocked
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                words,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontSize: 12,
                  height: 1.2,
                  color: standing.complete
                      ? palette.accentText
                      : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

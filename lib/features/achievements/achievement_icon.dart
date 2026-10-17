import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/assets/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';

/// An achievement's badge: its symbol on a round plate whose ring shows the
/// level (more ring segments filled, the higher the level). Locked badges
/// are greyed out. Uses the app's accent colours only.
///
/// The symbol is the artwork `assets/achievements/<id>.png` when the app
/// ships it (drop a file in, no code change; see docs/ux/ACHIEVEMENTS.md),
/// else the Material [icon]. Which artwork exists is read from the asset
/// manifest once at startup ([preloadArt]), so the badge stays synchronous.
class AchievementIcon extends StatelessWidget {
  const AchievementIcon({
    super.key,
    required this.icon,
    required this.tier,
    required this.tiers,
    this.id,
    this.size = 56,
  });

  /// The achievement's id: picks its artwork when there is one.
  final String? id;

  final IconData icon;

  /// The level reached, from 0; -1 when locked.
  final int tier;
  final int tiers;
  final double size;

  /// Plate colour per level, from the app's accents: green, blue, orange,
  /// red, then yellow.
  static const _levels = [
    AppColors.brandGreen,
    AppColors.infoBlue,
    AppColors.warningOrange,
    AppColors.danger,
    AppColors.placeYellow,
  ];

  static const artDir = AppAssetDirs.achievements;
  static Set<String> _art = const {};

  /// Reads which achievements have artwork (call once before they show).
  static Future<void> preloadArt([AssetBundle? bundle]) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(
        bundle ?? rootBundle,
      );
      _art = {
        for (final asset in manifest.listAssets())
          if (asset.startsWith(artDir) && asset.endsWith('.png'))
            asset.substring(artDir.length, asset.length - 4),
      };
    } catch (_) {
      _art = const {};
    }
  }

  /// The artwork of [id], or null when only the Material icon exists.
  static String? artFor(String? id) =>
      id != null && _art.contains(id) ? '$artDir$id.png' : null;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final locked = tier < 0;
    final art = artFor(id);
    final color = locked
        ? palette.disabled
        : _levels[tier.clamp(0, _levels.length - 1)];
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          segments: tiers,
          filled: tier + 1,
          color: color,
          track: palette.surfaceMuted,
        ),
        child: Padding(
          padding: EdgeInsets.all(size * 0.12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: locked
                  ? palette.surfaceMuted
                  : color.withValues(alpha: 0.16),
            ),
            child: art == null
                ? Icon(
                    icon,
                    size: size * 0.42,
                    color: locked ? palette.iconMuted : color,
                  )
                : Padding(
                    padding: EdgeInsets.all(size * 0.14),
                    // Locked: the artwork greyed, like the icon.
                    child: Image.asset(
                      art,
                      color: locked ? palette.iconMuted : null,
                      colorBlendMode: locked ? BlendMode.srcIn : null,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.segments,
    required this.filled,
    required this.color,
    required this.track,
  });

  final int segments;
  final int filled;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.07;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final n = segments.clamp(1, 12);
    const gap = 0.18;
    final sweep = (2 * 3.141592653589793) / n;
    for (var i = 0; i < n; i++) {
      paint.color = i < filled ? color : track;
      canvas.drawArc(
        rect.deflate(stroke / 2),
        -3.141592653589793 / 2 + i * sweep + (n > 1 ? gap / 2 : 0),
        sweep - (n > 1 ? gap : 0),
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.segments != segments ||
      old.filled != filled ||
      old.color != color ||
      old.track != track;
}

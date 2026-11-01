import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';

/// The profile's header in Profile v4 (Figma page 13, Round 5 and Profile
/// v4): a postcard. The cover photo with a white print margin, the person's
/// stamp half over its bottom edge, their name and town, what their stamp
/// "says" (the About me bubble) and their numbers.
///
/// [photoHeight] is 200 by default and 294 when pulled open; it animates.
class ProfilePostcard extends StatelessWidget {
  const ProfilePostcard({
    super.key,
    required this.photoHeight,
    required this.cover,
    required this.stamp,
    required this.name,
    required this.subtitle,
    required this.about,
    required this.counts,
    this.onCoverTap,
  });

  /// The default and pulled-open photo heights (dp).
  static const photoDefault = 200.0;
  static const photoOpen = 294.0;

  /// The stamp's size on the postcard and how far it hangs below the photo.
  static const stampSize = 116.0;
  static const stampOverhang = 58.0;

  /// From the stamp's centre to the card's right edge: where the bubble's
  /// tail points.
  static const stampCentreFromRight = 16 + stampSize / 2;

  final double photoHeight;
  final Widget cover;
  final Widget stamp;
  final Widget name;
  final Widget subtitle;
  final Widget about;
  final Widget counts;
  final VoidCallback? onCoverTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.passportShadow,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: onCoverTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: AppMotion.reveal,
                    curve: AppMotion.emphasizedCurve,
                    height: photoHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        cover,
                        // Keeps the white buttons readable on bright skies.
                        const Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: 96,
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.mediaShade,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(right: 8, bottom: -stampOverhang, child: stamp),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 14, stampSize + 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [name, const SizedBox(height: 4), subtitle],
            ),
          ),
          const SizedBox(height: 18),
          about,
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: palette.divider),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: counts,
          ),
        ],
      ),
    );
  }
}

/// The About me as something the stamp says: a soft bubble whose tail
/// points up at the stamp.
class StampSpeechBubble extends StatelessWidget {
  const StampSpeechBubble({
    super.key,
    required this.child,
    this.tailFromRight = ProfilePostcard.stampCentreFromRight - 8,
    this.color,
    this.onTap,
  });

  final Widget child;

  /// From the bubble's right edge to the tail's tip.
  final double tailFromRight;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fill = color ?? context.palette.background;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _BubblePainter(fill, tailFromRight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: child,
        ),
      ),
    );
  }

  /// The text style inside the bubble.
  static TextStyle textStyle(BuildContext context) => AppTextStyles.body
      .copyWith(fontSize: 14, height: 1.35, color: context.palette.textPrimary);
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.color, this.tailFromRight);

  final Color color;
  final double tailFromRight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)),
      paint,
    );
    // A curved tail rising from the top edge to the stamp.
    final tip = Offset(size.width - tailFromRight, -12);
    final tail = Path()
      ..moveTo(tip.dx - 16, 1)
      ..quadraticBezierTo(tip.dx - 4, -2, tip.dx, tip.dy)
      ..quadraticBezierTo(tip.dx + 2, -4, tip.dx + 6, 1)
      ..close();
    canvas.drawPath(tail, paint);
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.color != color || old.tailFromRight != tailFromRight;
}

/// The postcard when scrolled away: a strip of the cover photo across the
/// top with round bottom corners, the stamp and name inside it (option B).
class ProfilePhotoStrip extends StatelessWidget {
  const ProfilePhotoStrip({
    super.key,
    required this.cover,
    required this.stamp,
    required this.name,
    required this.username,
    this.leading,
  });

  /// The strip's height below the status bar.
  static const height = 80.0;

  final Widget cover;
  final Widget stamp;
  final String name;
  final String username;

  /// Before the stamp (a friend's profile: Back).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      height: top + height,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.passportShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          cover,
          const ColoredBox(color: AppColors.mediaScrim),
          Padding(
            padding: EdgeInsets.fromLTRB(16, top + 10, 150, 12),
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 10)],
                stamp,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onMedia,
                        ),
                      ),
                      Text(
                        '@$username',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          color: AppColors.onMediaMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A white icon in a dark circle, readable on any photo: the buttons on a
/// postcard (notifications, share, settings; Back and the menu on a friend's).
class PostcardIconButton extends StatelessWidget {
  const PostcardIconButton({
    super.key,
    required this.asset,
    required this.label,
    required this.onTap,
    this.size = 40,
  });

  final String asset;
  final String label;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) => DefaultIconButton(
    semanticLabel: label,
    onTap: onTap,
    child: SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.mediaScrim,
          shape: BoxShape.circle,
        ),
        child: Image.asset(asset, width: size, height: size),
      ),
    ),
  );
}

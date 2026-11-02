import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../data/models/profile_stamp.dart';
import '../../../shared/widgets/user/profile_stamp.dart';
import '../../../shared/widgets/user/user_stamp.dart';
import '../../../shared/widgets/user/verified_name.dart';

/// A friend's stamp in a box as tall as the tallest stamp shape (a
/// polaroid), so stamps of different shapes line up in rows and grids.
class FriendStamp extends StatelessWidget {
  const FriendStamp({
    super.key,
    required this.userId,
    required this.size,
    this.tilt = 0,
  });

  final String userId;
  final double size;
  final double tilt;

  /// The design's alternating tilt for the stamps in a row: -3, +3, -3...
  static double tiltAt(int index) => index.isEven ? -3 : 3;

  /// The box height for a stamp of [size].
  static double heightFor(double size) =>
      ProfileStamp.heightFor(StampShape.polaroid, size);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: heightFor(size),
    child: Center(
      child: UserStamp(userId: userId, size: size, tilt: tilt),
    ),
  );
}

/// A person in a v2 list: their stamp, the name in bold (with the verified
/// badge), a grey line under it and [trailing] (pills, a menu button).
class PersonRowV2 extends StatelessWidget {
  const PersonRowV2({
    super.key,
    required this.userId,
    required this.name,
    required this.subtitle,
    this.stampSize = 44,
    this.onTap,
    this.trailing,
    this.below,
  });

  final String userId;
  final String name;
  final String subtitle;
  final double stampSize;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Under the text (the request buttons).
  final Widget? below;

  /// Where a [CardV2Rows] hairline starts for rows of [stampSize].
  static double indentFor(double stampSize) => 16 + stampSize + 14;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            FriendStamp(userId: userId, size: stampSize),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  VerifiedName(
                    uid: userId,
                    name: name,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.bold,
                      color: palette.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      height: 1.25,
                      color: palette.textSecondary,
                    ),
                  ),
                  if (below != null) ...[const SizedBox(height: 8), below!],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// The "more" button of a row: three dots (no such icon in the set), a
/// 44 dp target.
class MoreDotsButton extends StatelessWidget {
  const MoreDotsButton({
    super.key,
    required this.onTap,
    required this.semanticLabel,
  });

  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color = context.palette.icon;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: AppPressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 4.5,
                    height: 4.5,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
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

/// "@username · 2 mutual friends" (just the username without any).
String personSubtitle(BuildContext context, String username, int mutual) =>
    mutual > 0
    ? '@$username · ${context.l10n.friendsMutualCount(mutual)}'
    : '@$username';

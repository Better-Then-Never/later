import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/motion/app_motion_widgets.dart';
import '../../../../shared/widgets/pin_mark.dart';
import '../../../../shared/widgets/v2/card_v2.dart';
import '../../../users/user_directory.dart';
import '../../pinned_friends_controller.dart';
import '../friend_stamp.dart';
import '../pin_friends_sheet.dart';

/// "Pinned on your profile" on My friends: the pinned friends' stamps with
/// their first names, an empty Pin slot while there is room, and Edit.
/// Both open the Pin a friend sheet.
class PinnedFriendsRow extends StatelessWidget {
  const PinnedFriendsRow({super.key});

  static const _stamp = 52.0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PinnedFriendsController>();
    final l10n = context.l10n;
    final pinned = controller.pinnedUids;
    void edit() => PinFriendsSheet.open(context, controller);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GroupLabelV2(
          l10n.friendsPinnedOnProfile,
          trailing: Semantics(
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: controller.isLoading ? null : edit,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.friendsEdit,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.bold,
                    color: context.palette.accentText,
                  ),
                ),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, uid) in pinned.indexed)
                _Slot(
                  key: ValueKey(uid),
                  label: _firstName(context, uid),
                  onTap: () => AppRoutes.toFriendProfile(context, uid),
                  child: FriendStamp(
                    userId: uid,
                    size: _stamp,
                    tilt: FriendStamp.tiltAt(i),
                  ),
                ),
              if (!controller.isLoading &&
                  pinned.length < PinnedFriendsController.maxPinned)
                _Slot(
                  label: l10n.profilePin,
                  muted: true,
                  onTap: edit,
                  child: const _EmptyPin(size: _stamp),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  static String _firstName(BuildContext context, String uid) {
    final name = context.select<UserDirectory, String>(
      (d) => d.profile(uid)?.name ?? '',
    );
    return name.trim().split(RegExp(r'\s+')).first;
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.muted = false,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: label,
      child: AppPressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: ExcludeSemantics(
            child: SizedBox(
              width: 66,
              child: Column(
                children: [
                  child,
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: muted ? palette.textMuted : palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The dashed square with a pin: room for one more pinned friend.
class _EmptyPin extends StatelessWidget {
  const _EmptyPin({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: size,
      height: FriendStamp.heightFor(size),
      child: Center(
        child: CustomPaint(
          painter: _DashedBorder(color: palette.textMuted),
          child: SizedBox.square(
            dimension: size,
            child: Center(child: PinMark(color: palette.icon, size: 20)),
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(1),
          const Radius.circular(8),
        ),
      );
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

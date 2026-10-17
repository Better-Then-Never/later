import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../../shared/widgets/count_badge.dart';
import '../../../shared/widgets/user/user_round_avatar.dart';
import '../chat_time.dart';

/// A chat in the list, styled like the friend rows: white card, round
/// avatar, bold name, grey preview of the last message, its time and the
/// unread count (grey when the chat is muted).
class ChatListItem extends StatelessWidget {
  const ChatListItem({
    super.key,
    required this.friendUid,
    required this.name,
    required this.preview,
    required this.onTap,
    this.timestamp,
    this.unread = 0,
    this.muted = false,
    this.avatar,
    this.semanticsLabel,
    this.pinned = false,
  });

  /// Kept at the top of the list (a small pin by the time).
  final bool pinned;

  final String friendUid;

  /// Instead of the friend's picture (a group's).
  final Widget? avatar;

  /// Read by a screen reader instead of the name.
  final String? semanticsLabel;
  final String name;

  /// Last message, already prefixed with "You: " for the user's own.
  final String preview;
  final DateTime? timestamp;
  final int unread;
  final bool muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final palette = context.palette;
    final hasUnread = unread > 0;

    return AppPressable(
      child: Container(
        decoration: BoxDecorations.whiteCard(context),
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screen.width * 0.02,
            vertical: 2,
          ),
          leading:
              avatar ??
              UserRoundAvatar(
                userId: friendUid,
                radius: UserRoundAvatar.listRadius(screen.width),
              ),
          title: Text(
            name,
            semanticsLabel: semanticsLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.listName(context),
          ),
          subtitle: Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: screen.width * 0.04,
              fontFamily: kAppFontFamily,
              // Unread chats read darker, like an unread notification.
              color: hasUnread ? palette.textPrimary : palette.textSecondary,
              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ChatTime.listLabel(
                  timestamp,
                  DateTime.now(),
                  l10n: context.l10n,
                ),
                style: TextStyle(
                  fontSize: screen.width * 0.032,
                  fontFamily: kAppFontFamily,
                  color: hasUnread && !muted
                      ? AppColors.brandGreen
                      : palette.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (pinned)
                    Semantics(
                      label: context.l10n.messagesPinned,
                      child: CustomPaint(
                        size: const Size(14, 16),
                        painter: _PinPainter(color: palette.iconMuted),
                      ),
                    ),
                  if (pinned && unread > 0) const SizedBox(width: 6),
                  CountBadge(
                    count: unread,
                    color: muted ? palette.iconMuted : AppColors.materialRed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small push pin: a round head on a short needle.
class _PinPainter extends CustomPainter {
  const _PinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final head = Offset(size.width / 2, size.height * 0.33);
    canvas
      ..drawCircle(head, size.width * 0.34, paint)
      ..drawLine(head, Offset(size.width / 2, size.height - 1), paint);
  }

  @override
  bool shouldRepaint(_PinPainter old) => old.color != color;
}

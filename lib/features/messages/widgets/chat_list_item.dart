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
  });

  final String friendUid;
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
          leading: UserRoundAvatar(
            userId: friendUid,
            radius: UserRoundAvatar.listRadius(screen.width),
          ),
          title: Text(
            name,
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
              CountBadge(
                count: unread,
                color: muted ? palette.iconMuted : AppColors.materialRed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

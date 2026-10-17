import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/data/models/app_notification.dart';
import 'package:later/features/notifications/notification_texts.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/features/notifications/widgets/notification_avatar.dart';
import 'package:later/features/notifications/widgets/notification_thumbnail.dart';
import 'package:later/features/notifications/widgets/notification_timestamp.dart';
import 'package:later/features/notifications/widgets/notification_unread_indicator.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/core/theme/app_text_styles.dart';
import 'package:later/features/users/user_directory.dart';

class NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.isSelected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _buildNotificationContent(context),
    );
  }

  Widget _buildNotificationContent(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: isSelected
          ? BoxDecoration(
              color: palette.selectedHighlight,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.infoBlue.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : BoxDecorations.whiteCard(context, borderRadius: 25).copyWith(
              color: notification.isRead
                  ? palette.surface
                  : palette.unreadHighlight,
            ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NotificationAvatar(
              avatarUrl: notification.fromUserAvatarUrl,
              userId: notification.fromUserId,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageRow(context),
                  const SizedBox(height: 4),
                  NotificationTimestamp(
                    // Null only while the server timestamp is pending.
                    timestamp: notification.timestamp ?? DateTime.now(),
                  ),
                ],
              ),
            ),
            if (notification.thumbnailImageUrl != null) ...[
              const SizedBox(width: 12),
              NotificationThumbnail(
                thumbnailImage: notification.thumbnailImageUrl,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(BuildContext context) {
    // The sentence comes from the notification type in the app's language;
    // the sender's name stays bold wherever the language puts it.
    final sentence = NotificationTexts.sentence(
      notification,
      l10n: context.l10n,
    );
    // Newer notifications store only the sender's id: their current name.
    final senderId = notification.fromUserId;
    final looked = context.select<UserDirectory, String?>(
      (d) => notification.fromUserName.isEmpty && senderId != null
          ? d.profile(senderId)?.name
          : null,
    );
    final name = notification.fromUserName.isNotEmpty
        ? notification.fromUserName
        : looked ?? '';
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 14,
                color: context.palette.textPrimary,
              ),
              children: [
                if (sentence.before.isNotEmpty) TextSpan(text: sentence.before),
                TextSpan(
                  text: name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: sentence.after),
              ],
            ),
          ),
        ),
        if (!selectionMode)
          NotificationUnreadIndicator(isRead: notification.isRead),
      ],
    );
  }
}

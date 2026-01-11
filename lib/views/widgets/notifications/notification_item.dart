import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/notifications/notification_avatar.dart';
import 'package:later/views/widgets/notifications/notification_thumbnail.dart';
import 'package:later/views/widgets/notifications/notification_timestamp.dart';
import 'package:later/views/widgets/notifications/notification_unread_indicator.dart';

class NotificationItem extends StatelessWidget {
  final String id;
  final String type;
  final String userName;
  final String userAvatar;
  final String message;
  final String? thumbnailImage;
  final DateTime timestamp;
  final bool isRead;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NotificationItem({
    super.key,
    required this.id,
    required this.type,
    required this.userName,
    required this.userAvatar,
    required this.message,
    this.thumbnailImage,
    required this.timestamp,
    required this.isRead,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            )
          : BoxDecorations.whiteCard(borderRadius: 25).copyWith(
              color: isRead ? Colors.white : Colors.blue.shade50,
            ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(25),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NotificationAvatar(userAvatar: userAvatar),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageRow(),
                  const SizedBox(height: 4),
                  NotificationTimestamp(timestamp: timestamp),
                ],
              ),
            ),
            if (thumbnailImage != null) ...[
              const SizedBox(width: 12),
              NotificationThumbnail(thumbnailImage: thumbnailImage),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow() {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: 'Irina',
                fontSize: 14,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: userName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: ' '),
                TextSpan(text: message),
              ],
            ),
          ),
        ),
        if (!selectionMode) NotificationUnreadIndicator(isRead: isRead),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_empty_inbox_info.dart';
import 'package:later/views/widgets/notifications/notification_item.dart';
import 'package:later/services/push_notification_service.dart';
import 'package:provider/provider.dart';

class NotificationsList extends StatelessWidget {
  final String filterType;

  const NotificationsList({super.key, required this.filterType});

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<PushNotificationService>(context);
    final allNotifications = notificationService.notifications;

    // Filter notifications based on type
    final filteredNotifications = filterType == 'All'
        ? allNotifications
        : allNotifications.where((n) {
            if (filterType == 'Replies') return n['type'] == 'reply';
            if (filterType == 'Comments') return n['type'] == 'comment';
            return true;
          }).toList();

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: () async {
        await notificationService.loadNotificationsFromFirestore();
      },
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          final originalIndex = allNotifications.indexOf(notification);
          
          return NotificationItem(
            type: notification['type'] ?? 'default',
            userName: notification['userName'] ?? 'Unknown User',
            userAvatar: notification['userAvatar'] ?? 'assets/images/icons/prof_page/no_photo.png',
            message: notification['message'] ?? '',
            thumbnailImage: notification['thumbnailImage'],
            timestamp: notification['timestamp'] ?? DateTime.now(),
            isRead: notification['isRead'] ?? false,
            index: originalIndex,
            onTap: () async {
              await notificationService.markAsRead(originalIndex);
              // Navigation logic based on notification type
              if (notification['capsuleId'] != null) {
                // TODO: Navigate to capsule detail page
                // Navigator.push(context, MaterialPageRoute(builder: (_) => CapsuleDetailPage(capsuleId: notification['capsuleId'])));
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    String iconPath;

    switch (filterType) {
      case 'All':
        title = 'Notifications';
        subtitle = 'Your notifications and activity will appear here';
        iconPath =
            'assets/images/icons/prof_page/notifications_button_black.png';
        break;
      case 'Replies':
        title = 'Replies';
        subtitle = 'Replies to your messages will appear here';
        iconPath = 'assets/images/icons/prof_page/reply.png';
        break;
      case 'Comments':
        title = 'Comments';
        subtitle = 'Comments on your Capsules will appear here';
        iconPath = 'assets/images/icons/prof_page/send_message.png';
        break;
      default:
        title = 'Notifications';
        subtitle = 'Your notifications and activity will appear here';
        iconPath =
            'assets/images/icons/prof_page/notifications_button_black.png';
    }

    return DefaultEmptyInboxInfo(
      message: title,
      subtitle: subtitle,
      assetPath: iconPath,
    );
  }
}
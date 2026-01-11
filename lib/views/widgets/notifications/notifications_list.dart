import 'package:flutter/material.dart';
import 'package:later/controllers/page_controllers/notifications_page_controller.dart';
import 'package:later/views/widgets/_common/default_elements/default_empty_inbox_info.dart';
import 'package:later/views/widgets/notifications/notification_item.dart';
import 'package:later/services/push_notification_service.dart';
import 'package:provider/provider.dart';

class NotificationsList extends StatelessWidget {
  final String filterType;
  final NotificationsPageController controller;

  const NotificationsList({
    super.key,
    required this.filterType,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = Provider.of<PushNotificationService>(context);
    final filteredNotifications = _filterNotifications(notificationService.notifications);

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return RefreshIndicator(
          color: Colors.black,
          onRefresh: () => notificationService.loadNotificationsFromFirestore(),
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: filteredNotifications.length,
            itemBuilder: (context, index) => _buildNotificationItem(
              context,
              filteredNotifications[index],
              notificationService.notifications.indexOf(filteredNotifications[index]),
              notificationService,
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterNotifications(List<Map<String, dynamic>> notifications) {
    if (filterType == 'All') return notifications;
    
    return notifications.where((n) {
      if (filterType == 'Replies') return n['type'] == 'reply';
      if (filterType == 'Comments') return n['type'] == 'comment';
      return false;
    }).toList();
  }

  Widget _buildNotificationItem(
    BuildContext context,
    Map<String, dynamic> notification,
    int originalIndex,
    PushNotificationService notificationService,
  ) {
    final notificationId = notification['id'] ?? '';
    
    return NotificationItem(
      key: ValueKey(notificationId),
      id: notificationId,
      type: notification['type'] ?? 'notification',
      userName: notification['userName'] ?? 'System',
      userAvatar: notification['userAvatar'] ?? 'assets/images/icons/prof_page/no_photo.png',
      message: notification['message'] ?? '',
      thumbnailImage: notification['thumbnailImage'],
      timestamp: notification['timestamp'] ?? DateTime.now(),
      isRead: notification['isRead'] ?? false,
      isSelected: controller.isSelected(notificationId),
      selectionMode: controller.isSelectionMode,
      onTap: () {
        if (controller.isSelectionMode) {
          controller.toggleSelection(notificationId);
        } else {
          _handleNotificationTap(context, notification, originalIndex);
        }
      },
      onLongPress: () {
        controller.toggleSelection(notificationId);
      },
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> notification,
    int index,
  ) async {
    final notificationService =
        Provider.of<PushNotificationService>(context, listen: false);
    await notificationService.markAsRead(index);

    final notificationType = notification['type'];
    final capsuleId = notification['capsuleId'];
    final userId = notification['userId'];

    // TODO: Implement navigation based on notification type
    if (notificationType == 'capsule' && capsuleId != null) {
      print('Navigate to capsule: $capsuleId');
    } else if (notificationType == 'follow' && userId != null) {
      print('Navigate to user profile: $userId');
    } else if (notificationType == 'comment' && capsuleId != null) {
      print('Navigate to capsule comments: $capsuleId');
    } else if (notificationType == 'reply' && capsuleId != null) {
      print('Navigate to reply in capsule: $capsuleId');
    }
  }

  Widget _buildEmptyState() {
    final config = _getEmptyStateConfig();
    return DefaultEmptyInboxInfo(
      message: config['title']!,
      subtitle: config['subtitle']!,
      assetPath: config['iconPath']!,
    );
  }

  Map<String, String> _getEmptyStateConfig() {
    switch (filterType) {
      case 'Replies':
        return {
          'title': 'Replies',
          'subtitle': 'Replies to your messages will appear here',
          'iconPath': 'assets/images/icons/prof_page/reply.png',
        };
      case 'Comments':
        return {
          'title': 'Comments',
          'subtitle': 'Comments on your Capsules will appear here',
          'iconPath': 'assets/images/icons/prof_page/send_message.png',
        };
      default:
        return {
          'title': 'Notifications',
          'subtitle': 'Your notifications and activity will appear here',
          'iconPath': 'assets/images/icons/prof_page/notifications_button_black.png',
        };
    }
  }
}
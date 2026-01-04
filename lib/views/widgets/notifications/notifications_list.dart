import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_empty_inbox_info.dart';
import 'package:later/views/widgets/notifications/notification_item.dart';
import 'package:later/services/push_notification_service.dart';

class NotificationsList extends StatefulWidget {
  final String filterType;

  const NotificationsList({super.key, required this.filterType});

  @override
  State<NotificationsList> createState() => _NotificationsListState();
}

class _NotificationsListState extends State<NotificationsList> {
  final PushNotificationService _notificationService =
      PushNotificationService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await _notificationService.loadNotificationsFromFirestore();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while loading
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    final allNotifications = _notificationService.notifications;

    // Filter notifications based on type
    final filteredNotifications = widget.filterType == 'All'
        ? allNotifications
        : allNotifications.where((n) {
            if (widget.filterType == 'Replies') return n['type'] == 'reply';
            if (widget.filterType == 'Comments') return n['type'] == 'comment';
            return true;
          }).toList();

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: Colors.black,
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return NotificationItem(
            type: notification['type'],
            userName: notification['userName'],
            userAvatar: notification['userAvatar'],
            message: notification['message'],
            thumbnailImage: notification['thumbnailImage'],
            timestamp: notification['timestamp'],
            isRead: notification['isRead'],
            index: allNotifications.indexOf(notification), // Add this line
            onTap: () {
              setState(() {
                _notificationService.markAsRead(
                  allNotifications.indexOf(notification),
                );
              });
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

    switch (widget.filterType) {
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

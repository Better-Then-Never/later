import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_empty_inbox_info.dart';

class NotificationsList extends StatelessWidget {
  final String filterType;
  
  const NotificationsList({
    super.key,
    required this.filterType,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Replace this with actual data check
    final bool hasNotifications = false;

    if (!hasNotifications) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // TODO: Add actual notification items here
      ],
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
        iconPath = 'assets/images/icons/prof_page/notifications_button_black.png';
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
        iconPath = 'assets/images/icons/prof_page/notifications_button_black.png';
    }

    return DefaultEmptyInboxInfo(
      message: title,
      subtitle: subtitle,
      assetPath: iconPath,
    );
  }
}
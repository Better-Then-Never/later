import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';

class NotificationTimestamp extends StatelessWidget {
  final DateTime timestamp;

  const NotificationTimestamp({
    super.key,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultText(
      _formatTimestamp(timestamp),
      fontSize: 12,
      color: Colors.grey[600],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
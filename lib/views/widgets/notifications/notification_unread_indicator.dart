import 'package:flutter/material.dart';

class NotificationUnreadIndicator extends StatelessWidget {
  final bool isRead;

  const NotificationUnreadIndicator({
    super.key,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    if (isRead) return const SizedBox.shrink();

    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(left: 8),
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
    );
  }
}
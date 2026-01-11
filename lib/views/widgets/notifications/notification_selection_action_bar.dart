import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';

class NotificationSelectionActionBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onMarkAsRead;

  const NotificationSelectionActionBar({
    super.key,
    required this.count,
    required this.onCancel,
    required this.onDelete,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          DefaultText(
            "$count",
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(width: 4),
          DefaultText(
            count == 1 ? "selected" : "selected",
            fontSize: 14,
            color: Colors.grey[600],
          ),
          const Spacer(),
          DefaultIconButton(
            onTap: onMarkAsRead,
            child: const Icon(
              Icons.mark_email_read,
              color: Colors.blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          DefaultIconButton(
            onTap: onDelete,
            child: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          DefaultIconButton(
            onTap: onCancel,
            child: const Icon(
              Icons.close,
              color: Colors.black,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
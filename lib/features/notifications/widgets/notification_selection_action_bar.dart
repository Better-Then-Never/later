import 'package:flutter/material.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/buttons/default_icon_button.dart';
import 'package:later/core/theme/app_colors.dart';

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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          DefaultText('$count', fontSize: 18, fontWeight: FontWeight.bold),
          const SizedBox(width: 4),
          DefaultText(
            count == 1 ? 'selected' : 'selected',
            fontSize: 14,
            color: AppColors.grey600,
          ),
          const Spacer(),
          DefaultIconButton(
            onTap: onMarkAsRead,
            child: const Icon(
              Icons.mark_email_read,
              color: AppColors.infoBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          DefaultIconButton(
            onTap: onDelete,
            child: const Icon(
              Icons.delete_outline,
              color: AppColors.redAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          DefaultIconButton(
            onTap: onCancel,
            child: const Icon(Icons.close, color: AppColors.black, size: 24),
          ),
        ],
      ),
    );
  }
}

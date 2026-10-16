import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/services/push_messaging_service.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../notification_router.dart';
import '../notifications_selection_controller.dart';
import '../notifications_store.dart';
import 'notification_item.dart';
import 'package:later/core/theme/app_colors.dart';

/// The tabs of the notifications page. "Replies" and "Comments" exist in the
/// design but no feature produces those types yet (see IDEAS_NOT_DONE.md).
enum NotificationFilter {
  all,
  replies,
  comments;

  bool accepts(AppNotification n) => switch (this) {
    NotificationFilter.all => true,
    NotificationFilter.replies => n.type == NotificationType.reply,
    NotificationFilter.comments => n.type == NotificationType.comment,
  };
}

class NotificationsList extends StatelessWidget {
  const NotificationsList({
    super.key,
    required this.filter,
    required this.selection,
  });

  final NotificationFilter filter;
  final NotificationsSelectionController selection;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NotificationsStore>();
    final items = store.notifications.where(filter.accepts).toList();

    if (items.isEmpty) return _EmptyState(filter: filter);

    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) {
        return RefreshIndicator(
          color: AppColors.black,
          // The list is live; the gesture is kept from the original design.
          onRefresh: () async {},
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final n = items[index];
              return NotificationItem(
                key: ValueKey(n.id),
                notification: n,
                isSelected: selection.isSelected(n.id),
                selectionMode: selection.isSelectionMode,
                onTap: () {
                  if (selection.isSelectionMode) {
                    selection.toggleSelection(n.id);
                  } else {
                    _open(context, n);
                  }
                },
                onLongPress: () => selection.toggleSelection(n.id),
              );
            },
          ),
        );
      },
    );
  }

  void _open(BuildContext context, AppNotification n) {
    context.read<NotificationsStore>().markRead([n.id]);
    context.read<NotificationRouter>().handle(
      NotificationTap.fromNotification(n),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final NotificationFilter filter;

  @override
  Widget build(BuildContext context) {
    return switch (filter) {
      NotificationFilter.replies => const DefaultEmptyInboxInfo(
        message: 'Replies',
        subtitle: 'Replies to your messages will appear here',
        assetPath: AppIcons.reply,
      ),
      NotificationFilter.comments => const DefaultEmptyInboxInfo(
        message: 'Comments',
        subtitle: 'Comments on your Capsules will appear here',
        assetPath: AppIcons.sendMessage,
      ),
      NotificationFilter.all => const DefaultEmptyInboxInfo(
        message: 'Notifications',
        subtitle: 'Your notifications and activity will appear here',
        assetPath: AppIcons.notificationsBlack,
      ),
    };
  }
}

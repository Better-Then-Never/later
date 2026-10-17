import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/services/push_messaging_service.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../notification_router.dart';
import '../notifications_selection_controller.dart';
import '../notifications_store.dart';
import 'notification_item.dart';
import '../../../shared/motion/app_motion_widgets.dart';

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
          color: context.palette.icon,
          // The list is live; the gesture is kept from the original design.
          onRefresh: () async {},
          child: AppStaggerScope(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final n = items[index];
                return AppStaggerItem(
                  key: ValueKey(n.id),
                  index: index,
                  child: NotificationItem(
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
                  ),
                );
              },
            ),
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
    final l10n = context.l10n;
    return switch (filter) {
      NotificationFilter.replies => DefaultEmptyInboxInfo(
        message: l10n.notificationsTabReplies,
        subtitle: l10n.notificationsEmptyReplies,
        assetPath: AppIcons.reply,
      ),
      NotificationFilter.comments => DefaultEmptyInboxInfo(
        message: l10n.notificationsTabComments,
        subtitle: l10n.notificationsEmptyComments,
        assetPath: AppIcons.sendMessage,
      ),
      NotificationFilter.all => DefaultEmptyInboxInfo(
        message: l10n.notificationsTitle,
        subtitle: l10n.notificationsEmptyAll,
        assetPath: AppIcons.notificationsBlack,
      ),
    };
  }
}

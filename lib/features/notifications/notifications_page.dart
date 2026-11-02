import 'package:flutter/material.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/features/notifications/notifications_selection_controller.dart';
import 'package:later/shared/widgets/popup/popup_notification_service.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/features/notifications/notifications_store.dart';
import 'package:later/shared/widgets/confirm_dialog.dart';
import 'package:later/shared/widgets/page_header.dart';
import 'package:later/features/notifications/widgets/notification_filter_pills.dart';
import 'package:later/features/notifications/widgets/notification_selection_action_bar.dart';
import 'package:later/features/notifications/widgets/notifications_list.dart';
import 'package:provider/provider.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/theme/app_motion.dart';

/// The notifications (Profile v4, reached from the bell): the v2 header,
/// the filter pills, then the list. A long press selects rows to mark read
/// or delete together.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late NotificationsSelectionController _controller;
  NotificationFilter _filter = NotificationFilter.all;

  @override
  void initState() {
    super.initState();
    _controller = NotificationsSelectionController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) => PopScope(
        canPop: !_controller.isSelectionMode,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _controller.clearSelection();
        },
        child: child!,
      ),
      child: Scaffold(
        backgroundColor: context.palette.background,
        body: Column(
          children: [
            PageHeaderV2(
              title: l10n.notificationsTitle,
              backLabel: l10n.commonBack,
              onBack: () => Navigator.maybePop(context),
            ),
            const SizedBox(height: 12),
            NotificationFilterPills(
              selected: _filter,
              onSelected: (filter) => setState(() => _filter = filter),
            ),
            const SizedBox(height: 4),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return AnimatedSize(
                  duration: AppMotion.of(context, AppMotion.slow),
                  curve: AppMotion.standardCurve,
                  child: _controller.isSelectionMode
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                          child: NotificationSelectionActionBar(
                            count: _controller.selectedCount,
                            onCancel: _controller.clearSelection,
                            onMarkAsRead: _handleMarkAsRead,
                            onDelete: _handleDelete,
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
            Expanded(
              child: NotificationsList(
                key: ValueKey(_filter),
                filter: _filter,
                selection: _controller,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMarkAsRead() async {
    final ids = _controller.selectedIds.toList();
    final count = ids.length;
    try {
      await context.read<NotificationsStore>().markRead(ids);
    } catch (e) {
      if (!mounted) return;
      PopupNotificationService.showError(
        context: context,
        message: AppFailure.from(e).message,
      );
      return;
    }
    if (!mounted) return;
    PopupNotificationService.showInfo(
      context: context,
      message: context.l10n.notificationsMarkedRead(count),
      position: NotificationPosition.bottom,
    );
    _controller.clearSelection();
  }

  void _handleDelete() {
    final l10n = context.l10n;
    ConfirmDialog.show(
      context: context,
      title: l10n.notificationsDeleteConfirm(_controller.selectedCount),
      confirmText: l10n.commonDelete,
      cancelText: l10n.commonCancel,
      confirmButtonColor: AppColors.materialRed,
      onConfirm: _performDelete,
    );
  }

  Future<void> _performDelete() async {
    final ids = _controller.selectedIds.toList();
    try {
      await context.read<NotificationsStore>().delete(ids);
    } catch (e) {
      if (!mounted) return;
      PopupNotificationService.showError(
        context: context,
        message: AppFailure.from(e).message,
      );
      return;
    }
    if (!mounted) return;
    PopupNotificationService.showInfo(
      context: context,
      message: context.l10n.notificationsDeleted(ids.length),
      position: NotificationPosition.bottom,
    );
    _controller.clearSelection();
  }
}

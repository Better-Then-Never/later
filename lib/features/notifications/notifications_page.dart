import 'package:flutter/material.dart';
import 'package:later/features/notifications/notifications_selection_controller.dart';
import 'package:later/shared/widgets/popup/popup_notification_service.dart';
import 'package:later/core/errors/app_failure.dart';
import 'package:later/features/notifications/notifications_store.dart';
import 'package:later/shared/widgets/confirm_dialog.dart';
import 'package:later/shared/widgets/page_header.dart';
import 'package:later/shared/widgets/buttons/go_back_button.dart';
import 'package:later/features/notifications/widgets/notification_filter_tabs.dart';
import 'package:later/features/notifications/widgets/notification_selection_action_bar.dart';
import 'package:later/features/notifications/widgets/notifications_list.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NotificationsSelectionController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = NotificationsSelectionController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: const Color(0xFFF6F6F6),
        body: Column(
          children: [
            PageHeader(
              mainText: 'Notifications',
              leadingButton: GoBackButton(context: context),
              actionButtonsRow: NotificationFilterTabs(
                controller: _tabController,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: _controller.isSelectionMode
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
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
              child: TabBarView(
                controller: _tabController,
                children: [
                  NotificationsList(
                    filter: NotificationFilter.all,
                    selection: _controller,
                  ),
                  NotificationsList(
                    filter: NotificationFilter.replies,
                    selection: _controller,
                  ),
                  NotificationsList(
                    filter: NotificationFilter.comments,
                    selection: _controller,
                  ),
                ],
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
      message: '$count notification${count > 1 ? 's' : ''} marked as read',
      position: NotificationPosition.bottom,
    );
    _controller.clearSelection();
  }

  void _handleDelete() {
    ConfirmDialog.show(
      context: context,
      title:
          'Delete ${_controller.selectedCount} notification${_controller.selectedCount > 1 ? 's' : ''}?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmButtonColor: Colors.red,
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
      message: '${ids.length} notification${ids.length > 1 ? 's' : ''} deleted',
      position: NotificationPosition.bottom,
    );
    _controller.clearSelection();
  }
}

import 'package:flutter/material.dart';
import 'package:later/controllers/page_controllers/notifications_page_controller.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/services/push_notification_service.dart';
import 'package:later/views/widgets/_common/default_elements/confirm_dialog.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/views/widgets/_common/premade_buttons/go_back_button.dart';
import 'package:later/views/widgets/notifications/notification_filter_tabs.dart';
import 'package:later/views/widgets/notifications/notification_selection_action_bar.dart';
import 'package:later/views/widgets/notifications/notifications_list.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late NotificationsPageController _controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller = NotificationsPageController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleBackButton,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        body: Column(
          children: [
            PageHeader(
              mainText: 'Notifications',
              leadingButton: GoBackButton(context: context),
              actionButtonsRow: NotificationFilterTabs(controller: _tabController),
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
                    filterType: 'All',
                    controller: _controller,
                  ),
                  NotificationsList(
                    filterType: 'Replies',
                    controller: _controller,
                  ),
                  NotificationsList(
                    filterType: 'Comments',
                    controller: _controller,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _handleBackButton() async {
    if (_controller.isSelectionMode) {
      _controller.clearSelection();
      return false;
    }
    return true;
  }

  Future<void> _handleMarkAsRead() async {
    final notificationService = context.read<PushNotificationService>();
    final selectedIds = _controller.selectedIds.toList();

    for (final id in selectedIds) {
      final index = notificationService.notifications
          .indexWhere((n) => n['id'] == id);
      if (index != -1) {
        await notificationService.markAsRead(index);
      }
    }

    if (!mounted) return;

    PopupNotificationService.showInfo(
      context: context,
      message:
          "${_controller.selectedCount} notification${_controller.selectedCount > 1 ? 's' : ''} marked as read",
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
    final notificationService = context.read<PushNotificationService>();
    final selectedIds = _controller.selectedIds.toList();

    for (final id in selectedIds) {
      final index = notificationService.notifications
          .indexWhere((n) => n['id'] == id);
      if (index != -1) {
        await notificationService.deleteNotification(index);
      }
    }

    if (!mounted) return;

    PopupNotificationService.showInfo(
      context: context,
      message:
          "${selectedIds.length} notification${selectedIds.length > 1 ? 's' : ''} deleted",
      position: NotificationPosition.bottom,
    );
    _controller.clearSelection();
  }
}
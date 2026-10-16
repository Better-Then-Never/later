import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/options_menu.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../friends/friends_store.dart';
import '../../friends/widgets/block_user.dart';
import '../chat_controller.dart';

/// Menu of an open chat: search, clear history, block or unblock.
class ChatOptionsSheet extends StatelessWidget {
  const ChatOptionsSheet({super.key, required this.controller});

  final ChatController controller;

  /// [context] must be the chat page's (it outlives this sheet).
  static Future<void> show(BuildContext context, ChatController controller) =>
      showCenteredSheet<void>(
        context,
        ChatOptionsSheet(controller: controller),
      );

  static Future<void> _confirmClear(
    BuildContext context,
    ChatController controller,
  ) => ConfirmDialog.show(
    context: context,
    title: 'Are you sure you want to clear chat history?',
    confirmText: 'Clear',
    onConfirm: () async {
      final failure = await controller.clearHistory();
      if (failure != null && context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: failure.message,
          position: NotificationPosition.bottom,
        );
      }
    },
  );

  @override
  Widget build(BuildContext context) {
    final friendUid = controller.friendUid;
    final blocked = context.select<FriendsStore, bool>(
      (s) => s.isBlocked(friendUid),
    );
    // The page's context: this sheet is gone when the follow-ups run.
    final page = Navigator.of(context).context;

    return OptionsMenu(
      children: [
        OptionsMenuItem(
          text: 'Search',
          isFirst: true,
          onPressed: () {
            Navigator.pop(context);
            if (!controller.isSearching) controller.toggleSearch();
          },
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: 'Clear history',
          textColor: AppColors.danger,
          onPressed: () {
            Navigator.pop(context);
            _confirmClear(page, controller);
          },
        ),
        const OptionsMenuDivider(),
        if (blocked)
          OptionsMenuItem(
            text: 'Unblock user',
            textColor: AppColors.brandGreen,
            isLast: true,
            onPressed: () {
              Navigator.pop(context);
              unblockUser(page, friendUid);
            },
          )
        else
          OptionsMenuItem(
            text: 'Block user',
            textColor: AppColors.danger,
            isLast: true,
            onPressed: () {
              Navigator.pop(context);
              confirmBlockUser(page, friendUid);
            },
          ),
      ],
    );
  }
}

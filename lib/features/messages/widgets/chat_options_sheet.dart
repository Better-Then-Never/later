import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/chat.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/options_menu.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../friends/friends_store.dart';
import '../../friends/widgets/block_user.dart';
import '../../settings/settings_store.dart';
import '../chat_controller.dart';
import 'group_friends_picker.dart';
import 'group_sheets.dart';

/// Menu of an open chat: search, mute, clear history, block or unblock; in
/// a group: search, members, add people, rename, mute, leave.
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
    title: context.l10n.messagesClearConfirmTitle,
    confirmText: context.l10n.messagesClearConfirm,
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

  static Future<void> _setPinned(
    BuildContext context,
    String chatId, {
    required bool pinned,
  }) async {
    final failure = await context.read<SettingsStore>().setChatPinned(
      chatId,
      pinned: pinned,
    );
    if (context.mounted) _report(context, failure, null);
  }

  /// "Pin to top" / "Unpin" for [chatId], as a menu item.
  static Widget _pinItem(BuildContext context, String chatId) {
    final pinned = context.select<SettingsStore, bool>(
      (s) => s.isPinned(chatId),
    );
    final page = Navigator.of(context).context;
    return OptionsMenuItem(
      text: pinned ? context.l10n.messagesUnpin : context.l10n.messagesPin,
      onPressed: () {
        Navigator.pop(context);
        _setPinned(page, chatId, pinned: !pinned);
      },
    );
  }

  static Future<void> _setMuted(
    BuildContext context,
    String chatId, {
    required bool muted,
  }) async {
    final failure = await context.read<SettingsStore>().setChatMuted(
      chatId,
      muted: muted,
    );
    if (!context.mounted) return;
    if (failure != null) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.bottom,
      );
    } else {
      PopupNotificationService.showSuccess(
        context: context,
        message: muted
            ? context.l10n.messagesMutedToast
            : context.l10n.messagesUnmutedToast,
        position: NotificationPosition.bottom,
      );
    }
  }

  static void _report(BuildContext context, AppFailure? failure, String? done) {
    if (!context.mounted) return;
    if (failure != null) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.bottom,
      );
    } else if (done != null) {
      PopupNotificationService.showSuccess(
        context: context,
        message: done,
        position: NotificationPosition.bottom,
      );
    }
  }

  static Future<void> _addPeople(
    BuildContext page,
    ChatController controller,
  ) async {
    final members = controller.chat?.members ?? const <String>[];
    final pick = await GroupFriendsPicker.show(
      page,
      title: page.l10n.messagesGroupAddPeople,
      actionText: page.l10n.messagesGroupAddPeople,
      exclude: members.toSet(),
      room: Chat.maxGroupMembers - members.length,
    );
    if (pick == null || !page.mounted) return;
    final failure = await controller.invite(pick.friends);
    if (page.mounted) _report(page, failure, page.l10n.messagesGroupInvited);
  }

  static Future<void> _rename(
    BuildContext page,
    ChatController controller,
  ) async {
    final name = await GroupRenameCard.show(page, controller.chat?.name ?? '');
    if (name == null || !page.mounted) return;
    final failure = await controller.renameGroup(name);
    if (page.mounted) _report(page, failure, null);
  }

  static Future<void> _leave(BuildContext page, ChatController controller) =>
      ConfirmDialog.show(
        context: page,
        title: page.l10n.messagesGroupLeaveConfirm(controller.chat?.name ?? ''),
        confirmText: page.l10n.messagesGroupLeave,
        onConfirm: () async {
          final failure = await controller.leaveGroup();
          if (!page.mounted) return;
          if (failure == null) {
            Navigator.of(page).pop();
          } else {
            _report(page, failure, null);
          }
        },
      );

  Widget _groupMenu(BuildContext context, String chatId, bool muted) {
    final page = Navigator.of(context).context;
    final l10n = context.l10n;
    final members = controller.chat?.members ?? const <String>[];
    void then(void Function() action) {
      Navigator.pop(context);
      action();
    }

    return OptionsMenu(
      children: [
        OptionsMenuItem(
          text: l10n.messagesMenuSearch,
          isFirst: true,
          onPressed: () => then(() {
            if (!controller.isSearching) controller.toggleSearch();
          }),
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: '${l10n.messagesGroupMembersTitle} · ${members.length}',
          onPressed: () => then(
            () => GroupMembersSheet.show(
              page,
              members: members,
              me: controller.myUid,
            ),
          ),
        ),
        const OptionsMenuDivider(),
        if (members.length < Chat.maxGroupMembers) ...[
          OptionsMenuItem(
            text: l10n.messagesGroupAddPeople,
            onPressed: () => then(() => _addPeople(page, controller)),
          ),
          const OptionsMenuDivider(),
        ],
        OptionsMenuItem(
          text: l10n.messagesGroupRename,
          onPressed: () => then(() => _rename(page, controller)),
        ),
        const OptionsMenuDivider(),
        _pinItem(context, chatId),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: muted ? l10n.messagesMenuUnmute : l10n.messagesMenuMute,
          onPressed: () => then(() => _setMuted(page, chatId, muted: !muted)),
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: l10n.messagesGroupLeave,
          textColor: AppColors.danger,
          isLast: true,
          onPressed: () => then(() => _leave(page, controller)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatId = controller.chatId;
    final muted = context.select<SettingsStore, bool>(
      (s) => chatId != null && s.isMuted(chatId),
    );
    if (controller.isGroup && chatId != null) {
      return _groupMenu(context, chatId, muted);
    }
    final friendUid = controller.friendUid!;
    final blocked = context.select<FriendsStore, bool>(
      (s) => s.isBlocked(friendUid),
    );
    // The page's context: this sheet is gone when the follow-ups run.
    final page = Navigator.of(context).context;
    final l10n = context.l10n;

    return OptionsMenu(
      children: [
        OptionsMenuItem(
          text: l10n.messagesMenuSearch,
          isFirst: true,
          onPressed: () {
            Navigator.pop(context);
            if (!controller.isSearching) controller.toggleSearch();
          },
        ),
        const OptionsMenuDivider(),
        if (chatId != null) ...[
          _pinItem(context, chatId),
          const OptionsMenuDivider(),
          OptionsMenuItem(
            text: muted ? l10n.messagesMenuUnmute : l10n.messagesMenuMute,
            onPressed: () {
              Navigator.pop(context);
              _setMuted(page, chatId, muted: !muted);
            },
          ),
          const OptionsMenuDivider(),
        ],
        OptionsMenuItem(
          text: l10n.messagesMenuClearHistory,
          textColor: AppColors.danger,
          onPressed: () {
            Navigator.pop(context);
            _confirmClear(page, controller);
          },
        ),
        const OptionsMenuDivider(),
        if (blocked)
          OptionsMenuItem(
            text: l10n.messagesMenuUnblock,
            textColor: AppColors.brandGreen,
            isLast: true,
            onPressed: () {
              Navigator.pop(context);
              unblockUser(page, friendUid);
            },
          )
        else
          OptionsMenuItem(
            text: l10n.messagesMenuBlock,
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

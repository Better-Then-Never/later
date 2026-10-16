import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../friends_store.dart';

/// Asks for confirmation, then blocks [uid]: they can no longer send this
/// user messages. Used by the friend menu and the chat menu.
Future<void> confirmBlockUser(BuildContext context, String uid) {
  // Read now: the menu that opened this is usually closing already.
  final store = context.read<FriendsStore>();
  return ConfirmDialog.show(
    context: context,
    title: 'Are you sure you want to block this user?',
    confirmText: 'Block',
    onConfirm: () async {
      if (store.isBusy(uid)) return;
      _report((await store.block(uid))?.message);
    },
  );
}

Future<void> unblockUser(BuildContext context, String uid) async {
  final store = context.read<FriendsStore>();
  if (store.isBusy(uid)) return;
  _report((await store.unblock(uid))?.message);
}

void _report(String? error) {
  final context = AppRoutes.navigatorKey.currentContext;
  if (error == null || context == null) return;
  PopupNotificationService.showError(
    context: context,
    message: error,
    position: NotificationPosition.bottom,
  );
}

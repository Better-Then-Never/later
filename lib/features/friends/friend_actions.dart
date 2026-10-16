import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/errors/app_failure.dart';
import '../../services/popup_notification_service.dart';
import 'friends_store.dart';

/// Runs friend actions from any screen and shows the same messages
/// everywhere. Pass the page's context (not a row's): the row usually
/// disappears when the action succeeds, which used to swallow the success
/// message (BUG-084).
class FriendActions {
  const FriendActions(this.context, {required this.position});

  final BuildContext context;
  final NotificationPosition position;

  FriendsStore get _store => context.read<FriendsStore>();

  Future<void> _run(
    String otherUid,
    Future<AppFailure?> Function(FriendsStore store) action, {
    required String message,
    bool success = false,
  }) async {
    final store = _store;
    if (store.isBusy(otherUid)) return;
    final failure = await action(store);
    if (!context.mounted) return;
    if (failure != null) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: position,
      );
    } else if (success) {
      PopupNotificationService.showSuccess(
        context: context,
        message: message,
        position: position,
      );
    } else {
      PopupNotificationService.showInfo(
        context: context,
        message: message,
        position: position,
      );
    }
  }

  Future<void> sendRequest(String to) {
    if (_store.sentTo.contains(to)) {
      PopupNotificationService.showInfo(
        context: context,
        message: 'Friend request already exists',
        position: position,
      );
      return Future.value();
    }
    return _run(
      to,
      (s) => s.sendRequest(to),
      message: 'Friend request sent!',
      success: true,
    );
  }

  Future<void> cancelRequest(String to) =>
      _run(to, (s) => s.cancelRequest(to), message: 'Friend request cancelled');

  Future<void> acceptRequest(String from) => _run(
    from,
    (s) => s.acceptRequest(from),
    message: 'Friend request accepted!',
    success: true,
  );

  Future<void> rejectRequest(String from) => _run(
    from,
    (s) => s.rejectRequest(from),
    message: 'Friend request rejected',
  );

  void dismissSuggestion(String uid) {
    _store.dismissSuggestion(uid);
    PopupNotificationService.showInfo(
      context: context,
      message: 'Suggested friend removed from the list!',
      position: position,
    );
  }
}

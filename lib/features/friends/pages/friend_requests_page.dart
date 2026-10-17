import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/buttons/go_back_button.dart';
import '../../users/user_directory.dart';
import '../friend_actions.dart';
import '../friends_store.dart';
import '../widgets/requests/friend_requests_received_row.dart';
import '../widgets/requests/friend_requests_sent_row.dart';
import '../widgets/requests/friend_requests_toggle_button.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';

/// Received and sent friend requests, live from [FriendsStore]; names come
/// from [UserDirectory] in one batched lookup.
class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  bool _showReceived = true;

  @override
  void dispose() {
    PopupNotificationService.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final store = context.watch<FriendsStore>();
    final directory = context.watch<UserDirectory>();
    // Actions use the page context: rows disappear on success (BUG-084).
    final actions = FriendActions(
      context,
      position: NotificationPosition.bottom,
    );

    final uids = (_showReceived ? store.receivedFrom : store.sentTo).toList()
      ..sort();

    Widget list;
    if (uids.isEmpty) {
      list = _showReceived
          ? DefaultEmptyInboxInfo(
              message: context.l10n.friendsRequestsEmptyTitle,
              subtitle: context.l10n.friendsRequestsEmptySubtitle,
              assetPath: AppIcons.friendsRequestPage,
            )
          : DefaultEmptyInboxInfo(
              message: context.l10n.friendsSentEmptyTitle,
              subtitle: context.l10n.friendsSentEmptySubtitle,
              assetPath: AppIcons.friendsRequestPage,
            );
    } else {
      list = ListView.builder(
        padding: const EdgeInsets.all(15),
        itemCount: uids.length,
        itemBuilder: (context, index) {
          final uid = uids[index];
          final profile = directory.profile(uid);
          if (profile == null && !directory.isResolved(uid)) {
            return const SizedBox(height: 80, child: Center());
          }
          final name = profile?.name ?? context.l10n.commonUnknownUser;
          final username =
              profile?.username ?? context.l10n.commonUnknownUsername;
          void open() => AppRoutes.toAddFriendProfile(context, uid);

          return _showReceived
              ? FriendRequestsReceivedRow(
                  uid: uid,
                  name: name,
                  username: username,
                  screenWidth: screenWidth,
                  isBusy: store.isBusy(uid),
                  onAccept: () => actions.acceptRequest(uid),
                  onReject: () => actions.rejectRequest(uid),
                  onTap: open,
                )
              : FriendRequestsSentRow(
                  uid: uid,
                  name: name,
                  username: username,
                  screenWidth: screenWidth,
                  isBusy: store.isBusy(uid),
                  onCancel: () => actions.cancelRequest(uid),
                  onTap: open,
                );
        },
      );
    }

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Column(
        children: [
          PageHeader(
            mainText: context.l10n.friendsRequestsTitle,
            leadingButton: GoBackButton(context: context),
            actionButtonsRow: Row(
              children: [
                FriendRequestsToggleButton(
                  onTap: () => setState(() => _showReceived = true),
                  text: context.l10n.friendsRequestsReceivedTab,
                  isSelected: _showReceived,
                ),
                const SizedBox(width: 12),
                FriendRequestsToggleButton(
                  onTap: () => setState(() => _showReceived = false),
                  text: context.l10n.friendsRequestsSentTab,
                  isSelected: !_showReceived,
                ),
              ],
            ),
          ),
          Expanded(child: list),
        ],
      ),
    );
  }
}

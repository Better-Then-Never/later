import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../services/popup_notification_service.dart';
import '../../../views/widgets/_common/default_elements/default_empty_inbox_info.dart';
import '../../../views/widgets/_common/default_elements/page_header.dart';
import '../../../views/widgets/_common/premade_buttons/go_back_button.dart';
import '../../users/user_directory.dart';
import '../friend_actions.dart';
import '../friends_store.dart';
import '../widgets/requests/friend_requests_received_row.dart';
import '../widgets/requests/friend_requests_sent_row.dart';
import '../widgets/requests/friend_requests_toggle_button.dart';

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
          ? const DefaultEmptyInboxInfo(
              message: 'No friend requests',
              subtitle:
                  'When someone sends you a friend request,\nit will appear here',
              assetPath: AppIcons.friendsRequestPage,
            )
          : const DefaultEmptyInboxInfo(
              message: 'No sent requests',
              subtitle: 'Friend requests you send\nwill appear here',
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
          final name = profile?.name ?? 'Unknown User';
          final username = profile?.username ?? 'unknown';
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
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          PageHeader(
            mainText: 'Friend Requests',
            leadingButton: GoBackButton(context: context),
            actionButtonsRow: Row(
              children: [
                FriendRequestsToggleButton(
                  onTap: () => setState(() => _showReceived = true),
                  text: 'Received',
                  isSelected: _showReceived,
                ),
                const SizedBox(width: 12),
                FriendRequestsToggleButton(
                  onTap: () => setState(() => _showReceived = false),
                  text: 'Sent',
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

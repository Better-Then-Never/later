import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/app_segmented_tabs.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/v2/card_v2.dart';
import '../../users/user_directory.dart';
import '../friend_actions.dart';
import '../friends_store.dart';
import '../widgets/friend_stamp.dart';
import '../widgets/requests/friend_requests_received_row.dart';
import '../widgets/requests/friend_requests_sent_row.dart';

/// Received and sent friend requests, live from [FriendsStore]; names come
/// from [UserDirectory] in one batched lookup. Opened from a friend request
/// notification (Add friends shows the same requests in its first tab).
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
    final l10n = context.l10n;
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
              message: l10n.friendsRequestsEmptyTitle,
              subtitle: l10n.friendsRequestsEmptySubtitle,
              assetPath: AppIcons.friendsRequestPage,
            )
          : DefaultEmptyInboxInfo(
              message: l10n.friendsSentEmptyTitle,
              subtitle: l10n.friendsSentEmptySubtitle,
              assetPath: AppIcons.friendsRequestPage,
            );
    } else {
      list = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          CardV2Rows(
            indent: PersonRowV2.indentFor(FriendRequestsReceivedRow.stampSize),
            children: [
              for (final uid in uids)
                if (directory.profile(uid) == null &&
                    !directory.isResolved(uid))
                  const SizedBox(height: 70)
                else
                  _row(context, store, directory, actions, uid),
            ],
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Column(
        children: [
          PageHeaderV2(
            title: l10n.friendsRequestsTitle,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.commonBack,
          ),
          const SizedBox(height: 8),
          AppSegmentedTabs(
            labels: [
              l10n.friendsRequestsReceivedTab,
              l10n.friendsRequestsSentTab,
            ],
            selected: _showReceived ? 0 : 1,
            onChanged: (i) => setState(() => _showReceived = i == 0),
          ),
          Expanded(child: list),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    FriendsStore store,
    UserDirectory directory,
    FriendActions actions,
    String uid,
  ) {
    final profile = directory.profile(uid);
    final name = profile?.name ?? context.l10n.commonUnknownUser;
    final username = profile?.username ?? context.l10n.commonUnknownUsername;
    void open() => AppRoutes.toAddFriendProfile(context, uid);
    return _showReceived
        ? FriendRequestsReceivedRow(
            key: ValueKey(uid),
            uid: uid,
            name: name,
            username: username,
            mutualFriends:
                profile?.friends.where(store.friendIds.contains).length ?? 0,
            isBusy: store.isBusy(uid),
            onAccept: () => actions.acceptRequest(uid),
            onReject: () => actions.rejectRequest(uid),
            onTap: open,
          )
        : FriendRequestsSentRow(
            key: ValueKey(uid),
            uid: uid,
            name: name,
            username: username,
            isBusy: store.isBusy(uid),
            onCancel: () => actions.cancelRequest(uid),
            onTap: open,
          );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../data/models/friend_request.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../profile/share/sharing_service.dart';
import '../../../shared/widgets/user/user_name_and_username.dart';
import '../friend_actions.dart';
import '../friends_store.dart';
import '../widgets/profile/add_friend_profile_action_button.dart';
import '../widgets/profile/add_friend_profile_header.dart';

/// Profile of someone who is not (yet) a friend: add, cancel, accept or
/// reject, live from [FriendsStore].
class AddFriendProfilePage extends StatefulWidget {
  final String userId;

  const AddFriendProfilePage({super.key, required this.userId});

  @override
  State<AddFriendProfilePage> createState() => _AddFriendProfilePageState();
}

class _AddFriendProfilePageState extends State<AddFriendProfilePage> {
  @override
  void dispose() {
    PopupNotificationService.hide();
    super.dispose();
  }

  void _onMainButton(FriendRelation relation, FriendActions actions) {
    switch (relation) {
      case FriendRelation.self:
        PopupNotificationService.showInfo(
          context: context,
          message: 'This is your account',
          position: NotificationPosition.center,
        );
      case FriendRelation.friends:
        AppRoutes.toFriendProfile(context, widget.userId);
      case FriendRelation.requestSent:
        PopupNotificationService.showInfo(
          context: context,
          message: 'Friend request is pending',
          position: NotificationPosition.center,
        );
      case FriendRelation.requestReceived:
        PopupNotificationService.showInfo(
          context: context,
          message: 'This user sent you a friend request',
          position: NotificationPosition.center,
        );
      case FriendRelation.none:
        actions.sendRequest(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    final relation = context.select<FriendsStore, FriendRelation>(
      (s) => s.relationTo(userId),
    );
    final busy = context.select<FriendsStore, bool>((s) => s.isBusy(userId));
    final actions = FriendActions(
      context,
      position: NotificationPosition.center,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.sizeOf(context).height * 0.45,
            ),
            child: Column(
              children: [
                AddFriendProfileHeader(
                  userId: userId,
                  bgHeight: MediaQuery.sizeOf(context).height * 0.32,
                  avatarRadius: 100,
                  onBack: () => Navigator.of(context).pop(),
                  onShare: () => SharingService.shareUserProfile(
                    context: context,
                    userId: userId,
                  ),
                ),
                const SizedBox(height: 110),
                UserNameAndUsername(
                  userId: userId,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
              ],
            ),
          ),
          AddFriendProfileActionButton(
            relation: relation,
            isBusy: busy,
            onAction: () => _onMainButton(relation, actions),
            onCancel: () => actions.cancelRequest(userId),
            onAccept: () => actions.acceptRequest(userId),
            onReject: () => actions.rejectRequest(userId),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../friends/pinned_friends_controller.dart';
import '../../../users/user_directory.dart';
import '../../../../shared/widgets/popup/popup_notification_service.dart';
import 'pinned_friend_avatar.dart';
import 'pinned_friend_options_dialog.dart';
import 'pinned_friends_selection_dialog.dart';
import 'package:later/core/theme/app_colors.dart';

class PinnedFriendsRow extends StatelessWidget {
  const PinnedFriendsRow({super.key});

  Future<void> _choosePinned(
    BuildContext context,
    PinnedFriendsController controller,
  ) async {
    Navigator.pop(context);
    final friends = controller.allFriends.toList();
    // One batched lookup for the names shown in the dialog.
    await context.read<UserDirectory>().resolveAll(friends);
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: AppColors.barrier,
      builder: (_) => PinnedFriendsSelectionDialog(
        pinnedUids: controller.pinnedUids,
        allFriends: friends,
      ),
    );
    if (chosen == null) return;
    await controller.setPinnedFriends(chosen);
    // Shown from the profile page: the sheet's own context is gone by now,
    // which used to swallow this message.
    if (!context.mounted) return;
    PopupNotificationService.showSuccess(
      context: context,
      message: 'Pinned friends updated successfully!',
      position: NotificationPosition.top,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PinnedFriendsController>();
    final size = MediaQuery.sizeOf(context).width / 3.8;

    if (controller.isLoading) {
      return const SizedBox(height: 80, child: Center());
    }

    if (controller.allFriends.isEmpty) {
      return const SizedBox(
        height: 70,
        child: Center(
          child: Text(
            'You have no friends yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final uid in controller.displayFriends)
          PinnedFriendAvatar(
            key: ValueKey(uid),
            uid: uid,
            size: size,
            onTap: () {
              showModalBottomSheet<void>(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                barrierColor: AppColors.barrier,
                builder: (_) => PinnedFriendOptionsDialog(
                  friendUid: uid,
                  onViewProfile: () {
                    Navigator.pop(context);
                    AppRoutes.toFriendProfile(context, uid);
                  },
                  onChoosePinned: () => _choosePinned(context, controller),
                ),
              );
            },
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/router/app_routes.dart';
import '../../../friends/pinned_friends_controller.dart';
import '../../../users/user_directory.dart';
import '../../../../shared/widgets/popup/popup_notification_service.dart';
import 'pinned_friend_avatar.dart';
import 'pinned_friend_options_dialog.dart';
import 'pinned_friends_selection_dialog.dart';
import '../../../../shared/widgets/app_sheets.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/core/theme/app_text_styles.dart';

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
    final chosen = await showEdgeSheet<List<String>>(
      context,
      (_) => PinnedFriendsSelectionDialog(
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
      message: context.l10n.profilePinnedUpdated,
      position: NotificationPosition.top,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PinnedFriendsController>();
    final size = MediaQuery.sizeOf(context).width / 3.8;

    // While loading: the tiles the friends will fill (F-39: it was blank).
    if (controller.isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: size,
              height: size,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: context.palette.skeleton,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
            ),
        ],
      );
    }

    // No friends yet: say so at body size and offer the way forward (F-39:
    // a 20 pt sentence with nothing to do).
    if (controller.allFriends.isEmpty) {
      return SizedBox(
        height: 70,
        child: Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => AppRoutes.toAddFriends(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.profileNoFriends,
                    style: TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.profileNoFriendsAction,
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ],
              ),
            ),
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
              showCenteredSheet<void>(
                context,
                PinnedFriendOptionsDialog(
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

import 'package:flutter/material.dart';
import 'package:later/controllers/widget_controllers/profile/pinned_friends_controller.dart';
import 'package:later/views/widgets/my_profile_page/my_friends_panel/profile_pinned_friends_row/on_pinned_friend_tap/pinned_friend_options_dialog.dart';
import 'package:provider/provider.dart';
import 'package:later/views/widgets/my_profile_page/my_friends_panel/profile_pinned_friends_row/on_pinned_friend_tap/pinned_friend_avatar.dart';

class PinnedFriendsRow extends StatelessWidget {
  const PinnedFriendsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PinnedFriendsController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final size = screenWidth / 3.8;

    if (controller.isLoading) {
      return SizedBox(height: 80, child: Center());
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

    return FutureBuilder<List<Map<String, String>>>(
      future: controller.getDisplayFriends(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center();
        }

        final friendsData = snapshot.data!;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: friendsData.map((friend) {
            final uid = friend['uid']!;
            return PinnedFriendAvatar(
              uid: uid,
              size: size,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  isScrollControlled: true,
                  barrierColor: Colors.black.withAlpha(128),
                  builder: (_) => PinnedFriendOptionsDialog(
                    friendUid: uid,
                    friendInfoMap: controller.friendInfoMap,
                    onViewProfile: () {
                      Navigator.pop(context);
                      controller.openFriendPage(context, uid);
                    },
                    onChoosePinned: () =>
                        controller.showChoosePinnedFriendsDialog(context),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}

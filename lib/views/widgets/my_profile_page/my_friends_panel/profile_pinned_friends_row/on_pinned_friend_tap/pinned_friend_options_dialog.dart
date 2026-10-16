import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/my_profile_page/profile_page_divider.dart';
import 'package:later/views/widgets/my_profile_page/my_friends_panel/profile_pinned_friends_row/on_pinned_friend_tap/pinned_friend_option_tile.dart';

class PinnedFriendOptionsDialog extends StatelessWidget {
  final String friendUid;
  final VoidCallback onViewProfile;
  final VoidCallback onChoosePinned;

  const PinnedFriendOptionsDialog({
    super.key,
    required this.friendUid,
    required this.onViewProfile,
    required this.onChoosePinned,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context),
      child: Center(
        child: Container(
          width: 250,
          decoration: BoxDecorations.whiteCard(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultText(
                context.select<UserDirectory, String>(
                  (d) => d.profile(friendUid)?.name ?? 'Unknown',
                ),
                fontSize: 22,
                color: const Color.fromARGB(255, 86, 201, 46),
                fontWeight: FontWeight.bold,
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              const ProfilePageDivider(
                width: double.infinity,
                color: Colors.black45,
              ),
              PinnedFriendOptionTile(
                onTap: onViewProfile,
                text: 'View profile page',
              ),
              const ProfilePageDivider(width: double.infinity),
              PinnedFriendOptionTile(
                onTap: onChoosePinned,
                text: 'Choose pinned friends',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

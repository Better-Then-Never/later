import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/my_profile_page/profile_page_divider.dart';
import 'package:later/views/widgets/profile/profile_pinned_friends_row/on_pinned_friend_tap/pinned_friend_option_tile.dart';

class PinnedFriendOptionsDialog extends StatelessWidget {
  final String friendUid;
  final Map<String, Map<String, String>> friendInfoMap;
  final VoidCallback onViewProfile;
  final VoidCallback onChoosePinned;

  const PinnedFriendOptionsDialog({
    super.key,
    required this.friendUid,
    required this.friendInfoMap,
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
              DefaultText(friendInfoMap[friendUid]?['name'] ?? 'Unknown'),
              ProfilePageDivider(width: double.infinity),
              PinnedFriendOptionTile(
                onTap: onViewProfile,
                text: 'View profile page',
              ),
              ProfilePageDivider(width: double.infinity),
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

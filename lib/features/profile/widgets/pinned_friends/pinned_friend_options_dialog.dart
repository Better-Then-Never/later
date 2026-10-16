import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/profile_page_divider.dart';
import 'package:later/features/profile/widgets/pinned_friends/pinned_friend_option_tile.dart';
import 'package:later/core/theme/app_colors.dart';

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
          decoration: BoxDecorations.whiteCard(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultText(
                context.select<UserDirectory, String>(
                  (d) => d.profile(friendUid)?.name ?? 'Unknown',
                ),
                fontSize: 22,
                color: AppColors.brandGreen,
                fontWeight: FontWeight.bold,
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              const ProfilePageDivider(
                width: double.infinity,
                color: AppColors.black45,
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

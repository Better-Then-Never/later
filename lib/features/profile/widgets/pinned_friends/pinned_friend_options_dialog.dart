import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/profile_page_divider.dart';
import 'package:later/features/profile/widgets/pinned_friends/pinned_friend_option_tile.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/core/l10n/l10n.dart';

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
    final l10n = context.l10n;
    final name = context.select<UserDirectory, String?>(
      (d) => d.profile(friendUid)?.name,
    );
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
                name ?? l10n.commonUnknownUser,
                fontSize: 22,
                color: AppColors.brandGreen,
                fontWeight: FontWeight.bold,
                padding: const EdgeInsets.symmetric(vertical: 4),
              ),
              // The text colour at 45 %: black45 in light, as before.
              ProfilePageDivider(
                width: double.infinity,
                color: context.palette.textPrimary.withAlpha(0x73),
              ),
              PinnedFriendOptionTile(
                onTap: onViewProfile,
                text: l10n.profileViewProfile,
              ),
              const ProfilePageDivider(width: double.infinity),
              PinnedFriendOptionTile(
                onTap: onChoosePinned,
                text: l10n.profileChoosePinned,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

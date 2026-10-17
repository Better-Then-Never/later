import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:later/shared/widgets/options_menu.dart';
import 'package:later/core/l10n/l10n.dart';

/// Menu of a pinned friend on the profile: view their profile, or choose
/// who is pinned. A centred card like every other menu
/// ([showCenteredSheet]).
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
    return OptionsMenu(
      children: [
        OptionsMenuTitle(name ?? l10n.commonUnknownUser),
        OptionsMenuItem(
          text: l10n.profileViewProfile,
          onPressed: onViewProfile,
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: l10n.profileChoosePinned,
          onPressed: onChoosePinned,
          isLast: true,
        ),
      ],
    );
  }
}

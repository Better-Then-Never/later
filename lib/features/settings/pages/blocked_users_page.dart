import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../data/models/user_profile.dart';
import '../../../shared/widgets/buttons/default_text_button.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/user/user_list_tile.dart';
import '../../../shared/widgets/user/user_row_skeleton.dart';
import '../../friends/friends_store.dart';
import '../../friends/widgets/block_user.dart';
import '../../users/user_directory.dart';
import '../widgets/settings_scaffold.dart';

/// People the user blocked, with a way to unblock each.
class BlockedUsersPage extends StatelessWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final blocked = context.select<FriendsStore, List<String>>(
      (s) => s.blocked.toList()..sort(),
    );
    final l10n = context.l10n;
    return SettingsScaffold(
      title: l10n.settingsBlockedUsers,
      description: l10n.settingsBlockedDescription,
      children: [
        if (blocked.isEmpty)
          DefaultEmptyInboxInfo(
            message: l10n.settingsBlockedEmpty,
            subtitle: l10n.settingsBlockedEmptyHint,
            assetPath: AppIcons.friendsRequestPage,
          )
        else
          OptionsSection(
            children: [for (final uid in blocked) _BlockedRow(uid: uid)],
          ),
      ],
    );
  }
}

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final user = context.select<UserDirectory, UserProfile?>(
      (d) => d.profile(uid),
    );
    final resolved = context.select<UserDirectory, bool>(
      (d) => d.isResolved(uid),
    );
    final busy = context.select<FriendsStore, bool>((s) => s.isBusy(uid));
    if (!resolved) return UserRowSkeleton(screenWidth: screenWidth);
    return UserListTile(
      uid: uid,
      name: user?.name ?? context.l10n.settingsDeletedAccount,
      username: user?.username ?? '',
      screenWidth: screenWidth,
      trailing: DefaultTextButton(
        text: busy
            ? context.l10n.settingsUnblocking
            : context.l10n.settingsUnblock,
        onTap: busy ? () {} : () => unblockUser(context, uid),
      ),
    );
  }
}

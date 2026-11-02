import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../shared/widgets/v2/card_v2.dart';
import '../../friends/friends_store.dart';
import '../../friends/widgets/friend_requests_count.dart';

/// "Add friends" on the profile (Profile v4): a v2 row with the number of
/// people who asked; with no friends yet, a line on how to find some.
class ProfilePageAddFriendsButton extends StatelessWidget {
  final String currentUserUid;

  const ProfilePageAddFriendsButton({super.key, required this.currentUserUid});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final none = context.select<FriendsStore, bool>(
      (s) => s.isLoaded && s.friendIds.isEmpty && s.incomingCount == 0,
    );
    return CardV2(
      child: RowV2(
        iconPath: AppIcons.profileAddFriend,
        title: l10n.profileAddFriends,
        subtitle: none ? l10n.profileNoFriendsAction : null,
        trailing: const FriendRequestCountBadge(),
        onTap: () => AppRoutes.toAddFriends(context),
      ),
    );
  }
}

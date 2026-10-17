import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../shared/widgets/buttons/default_button_with_icon.dart';
import '../friend_requests_count.dart';

class AddFriendsActionButtonsRow extends StatelessWidget {
  const AddFriendsActionButtonsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screen.width * 0.05,
        vertical: screen.height * 0.015,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: DefaultButtonWithIcon(
              onTap: () => AppRoutes.toShareProfile(context),
              assetPath: AppIcons.shareBlack,
              text: context.l10n.friendsShareProfile,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                DefaultButtonWithIcon(
                  onTap: () => AppRoutes.toFriendRequests(context),
                  assetPath: AppIcons.friendsRequest,
                  text: context.l10n.friendsRequestsButton,
                ),
                const Positioned(
                  top: -4,
                  right: -4,
                  child: FriendRequestCountBadge(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

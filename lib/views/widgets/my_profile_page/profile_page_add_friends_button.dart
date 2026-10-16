import 'package:flutter/material.dart';
import 'package:later/app/router/app_routes.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/features/friends/widgets/friend_requests_count.dart';

class ProfilePageAddFriendsButton extends StatelessWidget {
  final String currentUserUid;

  const ProfilePageAddFriendsButton({super.key, required this.currentUserUid});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => AppRoutes.toAddFriends(context),
      child: Container(
        width: screenWidth - 32,
        height: 45,
        decoration: BoxDecorations.whiteCard(),
        child: Stack(
          children: [
            Positioned(
              top: 3,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      AppIcons.profileAddFriend,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 18),
                  const DefaultText(
                    'Add friends',
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                ],
              ),
            ),
            const Positioned(
              top: 15,
              right: 12,
              child: FriendRequestCountBadge(),
            ),
          ],
        ),
      ),
    );
  }
}

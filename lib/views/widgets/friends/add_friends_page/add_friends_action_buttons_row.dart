import 'package:flutter/material.dart';
import 'package:later/views/pages/core_pages/share_profile_page.dart';
import 'package:later/views/pages/friends_pages/friend_requests_page.dart';
import 'package:later/views/widgets/_common/default_buttons/default_button_with_icon.dart';
import 'package:later/views/widgets/friends/friend_requests_count.dart';
import 'package:page_transition/page_transition.dart';

class AddFriendsActionButtonsRow extends StatelessWidget {
  const AddFriendsActionButtonsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
        vertical: MediaQuery.of(context).size.height * 0.015,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: DefaultButtonWithIcon(
              onTap: () {
                Navigator.push(
                  context,
                  PageTransition(
                    type: PageTransitionType.fade,
                    duration: const Duration(milliseconds: 10),
                    reverseDuration: const Duration(milliseconds: 10),
                    child: ShareProfilePage(),
                  ),
                );
              },
              assetPath: 'assets/images/icons/prof_page/share_button_black.png',
              text: 'Share Profile',
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                DefaultButtonWithIcon(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        duration: const Duration(milliseconds: 10),
                        reverseDuration: const Duration(milliseconds: 10),
                        child: FriendRequestsPage(),
                      ),
                    );
                  },
                  assetPath:
                      'assets/images/icons/friends_page/friend_request.png',
                  text: 'Requests',
                ),
                Positioned(
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

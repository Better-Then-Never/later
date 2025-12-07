import 'package:flutter/material.dart';
import 'package:later/views/pages/friends_pages/add_friends_page.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/friends/friend_requests_count.dart';
import 'package:page_transition/page_transition.dart';

class ProfilePageAddFriendsButton extends StatelessWidget {
  final String currentUserUid;

  const ProfilePageAddFriendsButton({super.key, required this.currentUserUid});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: const DefaultText(
            "Friends",
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.bottomToTop,
                duration: const Duration(milliseconds: 100),
                reverseDuration: const Duration(milliseconds: 100),
                child: AddFriendsPage(),
              ),
            );
          },
          
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
                          'assets/images/icons/prof_page/add_friend.png',
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
                FriendRequestCountBadge(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
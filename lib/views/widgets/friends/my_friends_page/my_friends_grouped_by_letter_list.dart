import 'package:flutter/material.dart';
import 'package:later/views/pages/friends_pages/your_friend_profile_page.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/user/user_list_tile.dart';
import 'package:page_transition/page_transition.dart';

class MyFriendsGroupedByLetterList extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groupedFriends;
  final double screenWidth;

  const MyFriendsGroupedByLetterList({
    super.key,
    required this.groupedFriends,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final sortedKeys = groupedFriends.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final letter = sortedKeys[index];
        final group = groupedFriends[letter]!;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DefaultText(
                letter,
                fontWeight: FontWeight.bold,
                fontSize: screenWidth * 0.055,
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecorations.whiteCard(),
                child: Column(
                  children: [
                    for (var friend in group)
                      UserListTile(
                        name: friend['name']!,
                        username: friend['username']!,
                        uid: friend['uid']!,
                        screenWidth: screenWidth,
                        onTap: () {
                          Navigator.push(
                            context,
                            PageTransition(
                              type: PageTransitionType.fade,
                              duration: const Duration(milliseconds: 10),
                              reverseDuration: const Duration(milliseconds: 10),
                              child: YourFriendProfilePage(friendUid: friend['uid']!),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

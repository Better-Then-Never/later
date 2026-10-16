import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../shared/widgets/user/user_list_tile.dart';
import '../../../../views/widgets/_common/decorations/box_decorations.dart';
import '../../../../views/widgets/_common/default_elements/default_text.dart';

class MyFriendsGroupedByLetterList extends StatelessWidget {
  final Map<String, List<UserProfile>> groupedFriends;
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
                    for (final friend in group)
                      UserListTile(
                        name: friend.name,
                        username: friend.username,
                        uid: friend.uid,
                        screenWidth: screenWidth,
                        onTap: () =>
                            AppRoutes.toFriendProfile(context, friend.uid),
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

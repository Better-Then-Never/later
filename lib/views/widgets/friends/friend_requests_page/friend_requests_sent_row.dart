import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/friends/friend_requests_page/friend_requests_action_button.dart';
import 'package:later/views/widgets/user/user_round_avatar.dart';

class FriendRequestsSentRow extends StatelessWidget {
  final String name;
  final String username;
  final String uid;
  final double screenWidth;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const FriendRequestsSentRow({
    super.key,
    required this.name,
    required this.username,
    required this.uid,
    required this.screenWidth,
    required this.onTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecorations.whiteCard(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              UserRoundAvatar(userId: uid, radius: screenWidth * 0.07),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultText(
                      name,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                      color: Colors.black,
                    ),
                    DefaultText(
                      '@$username',
                      fontSize: screenWidth * 0.035,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
              FriendRequestsActionButton(
                onTap: onCancel,
                color: const Color.fromARGB(255, 253, 65, 64),
                text: 'Cancel',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

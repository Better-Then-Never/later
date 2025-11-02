import 'package:flutter/material.dart';
import 'package:later/views/widgets/user/user_round_avatar.dart';

class SuggestedFriendRow extends StatelessWidget {
  final String userId;
  final String name;
  final String username;
  final VoidCallback onTapProfile;
  final VoidCallback onSendRequest;
  final VoidCallback onRemove;
  final bool isSent;
  final double screenWidth;

  const SuggestedFriendRow({
    super.key,
    required this.userId,
    required this.name,
    required this.username,
    required this.onTapProfile,
    required this.onSendRequest,
    required this.onRemove,
    required this.isSent,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: onTapProfile,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          leading: UserRoundAvatar(userId: userId, radius: screenWidth * 0.07),
          title: Text(
            name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
              fontFamily: 'Irina',
              color: Colors.black,
            ),
          ),
          subtitle: Text(
            '@$username',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontFamily: 'Irina',
              color: const Color(0xFF5E5E5E),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              isSent
                  ? Image.asset(
                      'assets/images/icons/friends_page/pending.png',
                      width: screenWidth * 0.09,
                      height: screenWidth * 0.09,
                    )
                  : GestureDetector(
                      onTap: onSendRequest,
                      child: Image.asset(
                        'assets/images/icons/prof_page/add_friend.png',
                        width: screenWidth * 0.09,
                        height: screenWidth * 0.09,
                      ),
                    ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Image.asset(
                  'assets/images/icons/friends_page/delete_reset.png',
                  width: screenWidth * 0.07,
                  height: screenWidth * 0.07,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

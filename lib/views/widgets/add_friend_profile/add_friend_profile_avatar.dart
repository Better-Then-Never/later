import 'package:flutter/material.dart';
import 'package:later/views/widgets/user/user_round_avatar.dart';

class AddFriendProfileAvatar extends StatelessWidget {
  final String userId;
  final double screenWidth;
  final double bgHeight;
  final double avatarRadius;

  const AddFriendProfileAvatar({
    super.key,
    required this.userId,
    required this.screenWidth,
    required this.bgHeight,
    required this.avatarRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: bgHeight - avatarRadius,
      left: (screenWidth - avatarRadius * 2) / 2,
      child: Material(
        elevation: 8,
        shape: const CircleBorder(),
        child: UserRoundAvatar(userId: userId, radius: avatarRadius),
      ),
    );
  }
}

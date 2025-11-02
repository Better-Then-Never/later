import 'package:flutter/material.dart';
import 'package:later/views/widgets/user/user_profile_image.dart';

class UserRoundAvatar extends StatelessWidget {
  final String userId;
  final double radius;

  const UserRoundAvatar({
    super.key,
    required this.userId,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: UserProfileImage(userId: userId),
      ),
    );
  }
}

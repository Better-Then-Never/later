import 'package:flutter/material.dart';
import 'package:later/views/widgets/user/user_profile_image.dart';

class UserSquareAvatar extends StatelessWidget {
  final String userId;
  final double size;
  final double borderRadius;

  const UserSquareAvatar({
    super.key,
    required this.userId,
    required this.size,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: UserProfileImage(userId: userId),
      ),
    );
  }
}

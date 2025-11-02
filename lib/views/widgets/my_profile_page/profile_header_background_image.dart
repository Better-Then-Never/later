import 'package:flutter/material.dart';
import 'package:later/views/widgets/user/user_background_image.dart';

class ProfileHeaderBackground extends StatelessWidget {
  final String userId;
  final double height;
  final double borderRadius;

  const ProfileHeaderBackground({
    super.key,
    required this.userId,
    this.height = 230,
    this.borderRadius = 25,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(borderRadius),
        bottomRight: Radius.circular(borderRadius),
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: UserBackgroundImage(userId: userId),
      ),
    );
  }
}

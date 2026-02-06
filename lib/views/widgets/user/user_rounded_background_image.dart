import 'package:flutter/material.dart';
import 'package:later/views/widgets/user/user_background_image.dart';

class UserRoundedBackgroundImage extends StatelessWidget {
  final String userId;
  final double height;

  const UserRoundedBackgroundImage({
    super.key,
    required this.userId,
    this.height = 270,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(25),
        bottomRight: Radius.circular(25),
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: UserBackgroundImage(userId: userId),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'user_profile_image.dart';

class UserRoundAvatar extends StatelessWidget {
  final String userId;
  final double radius;

  const UserRoundAvatar({
    super.key,
    required this.userId,
    required this.radius,
  });

  /// The avatar of a person in a list row: 7 % of the screen width, at most
  /// 54 dp across, because ListTile caps its leading widget at 56 dp and a
  /// bigger circle was squashed into an ellipse on wide phones (F-30).
  static double listRadius(double screenWidth) =>
      math.min(screenWidth * 0.07, 27);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: UserProfileImage(userId: userId, small: radius <= 48),
      ),
    );
  }
}

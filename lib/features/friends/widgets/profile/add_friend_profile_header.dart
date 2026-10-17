import 'package:flutter/material.dart';
import 'package:later/shared/widgets/shadow_top_overlay.dart';
import 'package:later/features/friends/widgets/profile/friend_profile_action_buttons_row.dart';
import 'package:later/shared/widgets/user/user_rounded_background_image.dart';
import 'add_friend_profile_avatar.dart';

class AddFriendProfileHeader extends StatelessWidget {
  final String userId;
  final double bgHeight;
  final double avatarRadius;
  final VoidCallback onBack;
  final VoidCallback onShare;

  /// Report and block (none on the user's own profile).
  final VoidCallback? onOptions;

  const AddFriendProfileHeader({
    super.key,
    required this.userId,
    required this.bgHeight,
    required this.avatarRadius,
    required this.onBack,
    required this.onShare,
    this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        UserRoundedBackgroundImage(userId: userId, height: bgHeight),
        ShadowTopOverlay(width: screenWidth),
        ProfileActionButtonsRow(
          onBack: onBack,
          onShare: onShare,
          onOptions: onOptions,
        ),
        AddFriendProfileAvatar(
          userId: userId,
          screenWidth: screenWidth,
          bgHeight: bgHeight,
          avatarRadius: avatarRadius,
        ),
      ],
    );
  }
}

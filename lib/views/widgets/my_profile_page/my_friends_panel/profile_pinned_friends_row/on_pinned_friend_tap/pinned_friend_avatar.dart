import 'package:flutter/material.dart';
import 'package:later/services/user_image_service.dart';
import 'package:later/views/widgets/user/user_profile_image.dart';

class PinnedFriendAvatar extends StatelessWidget {
  final String uid;
  final double size;
  final VoidCallback onTap;

  const PinnedFriendAvatar({
    super.key,
    required this.uid,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              )),
        clipBehavior: Clip.hardEdge,
        child: UserProfileImage(
          userId: uid,
          placeholderType: ProfilePlaceholderType.pinnedFriend,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:later/services/firebase_storage_service.dart';
import 'package:later/views/widgets/_common/default_elements/default_loading_container.dart';
import 'package:later/views/widgets/user/user_avatar.dart';

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
        child: FutureBuilder<String?>(
          future: FirebaseStorageService.getOriginalProfileImageUrl(userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return DefaultLoadingContainer(
                width: avatarRadius * 2,
                height: avatarRadius * 2,
                borderRadius: BorderRadius.circular(avatarRadius),
              );
            }

            return UserAvatar(imageUrl: snapshot.data, radius: avatarRadius);
          },
        ),
      ),
    );
  }
}

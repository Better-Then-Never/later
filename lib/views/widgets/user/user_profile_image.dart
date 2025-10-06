import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_image_service.dart';

class UserProfileImage extends StatelessWidget {
  final String userId;
  const UserProfileImage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<UserImageService>().getProfileNotifier(
      userId,
    );

    return ValueListenableBuilder<ImageProvider>(
      valueListenable: notifier,
      builder: (_, image, __) {
        return Image(image: image, fit: BoxFit.cover);
      },
    );
  }
}

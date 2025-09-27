import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_image_service.dart';

class UserProfileImage extends StatelessWidget {
  final String userId;

  const UserProfileImage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserImageService>(
      builder: (context, imageService, child) {
        final imageProvider = imageService.getProfileImage(userId);
        return Image(image: imageProvider, fit: BoxFit.cover);
      },
    );
  }
}

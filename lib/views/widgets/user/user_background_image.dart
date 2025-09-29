import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_image_service.dart';

class UserBackgroundImage extends StatelessWidget {
  final String userId;
  final BoxFit fit;

  const UserBackgroundImage({
    super.key,
    required this.userId,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserImageService>(
      builder: (context, imageService, child) {
        final imageProvider = imageService.getBackgroundImage(userId);
        return Image(image: imageProvider, fit: fit);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_image_service.dart';

class UserBackgroundImage extends StatelessWidget {
  final String userId;
  const UserBackgroundImage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<UserImageService>().getBackgroundNotifier(
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/profile_image_cache.dart';

/// A user's profile background, or the default background.
class UserBackgroundImage extends StatelessWidget {
  const UserBackgroundImage({super.key, required this.userId});

  final String userId;

  static const _placeholder = AssetImage(AppIcons.profileBackgroundPlaceholder);

  @override
  Widget build(BuildContext context) {
    final url = context.select<ProfileImageCache, String?>(
      (cache) => cache.url(userId, ProfileImageKind.background),
    );
    if (url == null) return const Image(image: _placeholder, fit: BoxFit.cover);
    return Image.network(
      url,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) =>
          const Image(image: _placeholder, fit: BoxFit.cover),
    );
  }
}

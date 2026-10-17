import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/profile_image_cache.dart';
import 'user_profile_image.dart';

/// A user's profile background, or the default background (the skeleton
/// colour while the lookup runs).
class UserBackgroundImage extends StatelessWidget {
  const UserBackgroundImage({super.key, required this.userId});

  final String userId;

  static const _placeholder = AssetImage(AppIcons.profileBackgroundPlaceholder);

  @override
  Widget build(BuildContext context) {
    final url = context.select<ProfileImageCache, String?>(
      (cache) => cache.url(userId, ProfileImageKind.background),
    );
    final resolved = context.select<ProfileImageCache, bool>(
      (cache) => cache.isResolved(userId, ProfileImageKind.background),
    );
    if (url == null) {
      return resolved
          ? const Image(image: _placeholder, fit: BoxFit.cover)
          : ColoredBox(color: context.palette.skeleton);
    }
    return NetworkPicture(url: url, fallback: _placeholder);
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/profile_image_cache.dart';
import 'user_profile_image.dart';

/// A user's profile background, or [BackgroundPlaceholder] (the skeleton
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
          ? const BackgroundPlaceholder()
          : ColoredBox(color: context.palette.skeleton);
    }
    return NetworkPicture(url: url, fallback: _placeholder);
  }
}

/// The background of a profile without a picture: a deep brand gradient, so
/// the white name and counts drawn on it stay readable (F-40: it was a flat
/// light grey under white text).
class BackgroundPlaceholder extends StatelessWidget {
  const BackgroundPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandGreen, AppColors.infoBlue],
        ),
      ),
      child: ColoredBox(color: AppColors.mediaShade),
    );
  }
}

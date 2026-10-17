import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/profile_image_cache.dart';
import 'user_placeholder.dart';
import 'user_profile_image.dart';

/// A user's profile background, or [BackgroundPlaceholder] (the skeleton
/// colour while the lookup runs).
class UserBackgroundImage extends StatelessWidget {
  const UserBackgroundImage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final url = context.select<ProfileImageCache, String?>(
      (cache) => cache.url(userId, ProfileImageKind.background),
    );
    final resolved = context.select<ProfileImageCache, bool>(
      (cache) => cache.isResolved(userId, ProfileImageKind.background),
    );
    final placeholder = BackgroundPlaceholder(userId: userId);
    if (url == null) {
      return resolved
          ? placeholder
          : ColoredBox(color: context.palette.skeleton);
    }
    return NetworkPicture(url: url, fallback: placeholder);
  }
}

/// The background of a profile without a picture: the person's gradient
/// ([UserGradient], F-40), shaded so the white name and counts drawn on it
/// stay readable (it was a flat light grey under white text, then one
/// gradient for everyone).
class BackgroundPlaceholder extends StatelessWidget {
  const BackgroundPlaceholder({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: UserGradient.of(userId)),
      child: const ColoredBox(color: AppColors.mediaShade),
    );
  }
}

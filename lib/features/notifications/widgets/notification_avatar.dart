import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/profile_image_cache.dart';

/// Sender avatar: the URL stored on the notification, else the sender's
/// current profile picture, else the "no photo" placeholder (BUG-031: empty
/// or asset-path avatars used to throw and render a grey circle).
class NotificationAvatar extends StatelessWidget {
  const NotificationAvatar({
    super.key,
    this.avatarUrl,
    this.userId,
    this.radius = 24,
  });

  final String? avatarUrl;
  final String? userId;
  final double radius;

  @override
  Widget build(BuildContext context) {
    // select() must run on every build, so it is not inside a condition.
    final cached = context.select<ProfileImageCache, String?>(
      (cache) => cache.url(userId ?? '', ProfileImageKind.profile),
    );
    final url = avatarUrl ?? cached;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.placeholderGrey,
      backgroundImage: url != null
          ? NetworkImage(url)
          : const AssetImage(AppIcons.profileNoPhoto) as ImageProvider,
      onBackgroundImageError: url != null ? (_, _) {} : null,
    );
  }
}

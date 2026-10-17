import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/app_image_cache.dart';
import '../../../data/services/profile_image_cache.dart';
import '../../../shared/widgets/user/user_placeholder.dart';

/// Sender avatar: the URL stored on the notification, else the sender's
/// current profile picture, else their [UserPlaceholder] (F-40), or the "no
/// photo" drawing for notifications without a sender (BUG-031: empty or
/// asset-path avatars used to throw and render a grey circle).
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
    final sender = userId;
    if (url == null && sender != null && sender.isNotEmpty) {
      return ClipOval(
        child: SizedBox.square(
          dimension: radius * 2,
          child: UserPlaceholder(userId: sender),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: context.palette.skeleton,
      backgroundImage: url != null
          ? AppImageCache.provider(
              url,
              width: AppImageCache.decodeWidth(
                radius * 2,
                MediaQuery.devicePixelRatioOf(context),
              ),
            )
          : const AssetImage(AppIcons.profileNoPhoto) as ImageProvider,
      onBackgroundImageError: url != null ? (_, _) {} : null,
    );
  }
}

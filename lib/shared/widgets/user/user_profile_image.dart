import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/app_image_cache.dart';
import '../../../data/services/profile_image_cache.dart';
import 'user_placeholder.dart';

/// A user's profile picture, or their [UserPlaceholder] (their gradient
/// and initial).
///
/// Resolved through [ProfileImageCache], so an upload or delete shows up
/// everywhere at once and a missing picture is retried later instead of
/// being remembered forever. [small] uses the 256 px thumbnail (falls back
/// to the full picture for accounts that have none). While the lookup runs
/// the shape is filled with the skeleton colour, so a picture does not
/// appear after a flash of the "no photo" drawing.
class UserProfileImage extends StatelessWidget {
  const UserProfileImage({super.key, required this.userId, this.small = true});

  final String userId;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final url = context.select<ProfileImageCache, String?>(
      (cache) => cache.url(userId, ProfileImageKind.profile, small: small),
    );
    final resolved = context.select<ProfileImageCache, bool>(
      (cache) =>
          cache.isResolved(userId, ProfileImageKind.profile, small: small),
    );
    final placeholder = UserPlaceholder(userId: userId);
    if (url == null) {
      return resolved
          ? placeholder
          : ColoredBox(color: context.palette.skeleton);
    }
    return NetworkPicture(url: url, fallback: placeholder);
  }
}

/// A cached picture filling its box, decoded at a bucketed size; [fallback]
/// shows when it cannot be loaded.
class NetworkPicture extends StatelessWidget {
  const NetworkPicture({super.key, required this.url, required this.fallback});

  final String url;

  /// Shown when the picture cannot be loaded.
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? AppImageCache.decodeWidth(
                constraints.maxWidth,
                MediaQuery.devicePixelRatioOf(context),
              )
            : null;
        return Image(
          image: AppImageCache.provider(url, width: width),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, sync) => sync || frame != null
              ? child
              : ColoredBox(color: context.palette.skeleton),
          errorBuilder: (_, _, _) => fallback,
        );
      },
    );
  }
}

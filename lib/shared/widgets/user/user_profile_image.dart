import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/profile_image_cache.dart';

/// A user's profile picture, or the "no photo" placeholder.
///
/// Resolved through [ProfileImageCache], so an upload or delete shows up
/// everywhere at once and a missing picture is retried later instead of
/// being remembered forever. [small] uses the 256 px thumbnail (falls back
/// to the full picture for accounts that have none).
class UserProfileImage extends StatelessWidget {
  const UserProfileImage({super.key, required this.userId, this.small = true});

  final String userId;
  final bool small;

  static const _placeholder = AssetImage(AppIcons.profileNoPhoto);

  @override
  Widget build(BuildContext context) {
    final url = context.select<ProfileImageCache, String?>(
      (cache) => cache.url(userId, ProfileImageKind.profile, small: small),
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

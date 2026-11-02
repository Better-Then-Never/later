import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/app_image_cache.dart';
import '../../../data/services/profile_image_cache.dart';
import '../../../features/users/user_directory.dart';
import 'profile_stamp.dart';

/// Anyone's stamp (Profile v4): their photo in the shape and colour they
/// chose, looked up by [userId]. People appear like this everywhere: lists,
/// notifications, share sheets, their postcard.
class UserStamp extends StatelessWidget {
  const UserStamp({
    super.key,
    required this.userId,
    required this.size,
    this.tilt = 0,
    this.small = true,
    this.elevation = 2,
  });

  final String userId;
  final double size;
  final double tilt;

  /// The 256 px thumbnail (lists); false for the full picture (a postcard).
  final bool small;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final profile = context.select<UserDirectory, UserProfile?>(
      (d) => d.profile(userId),
    );
    final url = context.select<ProfileImageCache, String?>(
      (c) => c.url(userId, ProfileImageKind.profile, small: small),
    );
    final resolved = context.select<ProfileImageCache, bool>(
      (c) => c.isResolved(userId, ProfileImageKind.profile, small: small),
    );
    final name = profile?.name ?? '';
    return Semantics(
      image: true,
      label: name.isEmpty ? null : context.l10n.profileStampLabel(name),
      child: ProfileStamp(
        style: profile?.stamp ?? const ProfileStampStyle(),
        size: size,
        photo: url == null
            ? null
            : AppImageCache.provider(url, width: (size * 3).round()),
        initial: resolved ? (profile?.initial ?? '') : '',
        caption: name.split(' ').first.toLowerCase(),
        tilt: tilt,
        elevation: elevation,
      ),
    );
  }
}

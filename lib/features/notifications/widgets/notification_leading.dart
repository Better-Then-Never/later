import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/profile_stamp.dart';
import '../../../data/services/app_image_cache.dart';
import '../../../shared/widgets/user/profile_stamp.dart';
import '../../../shared/widgets/user/user_stamp.dart';
import '../../achievements/achievement_catalog.dart';
import '../../achievements/achievement_icon.dart';

/// What a notification row starts with (Profile v4): the person as their
/// stamp; an opened capsule as its photo on a stamp; a place alert as the
/// pin; an achievement as its badge; the Later logo for the rest.
class NotificationLeading extends StatelessWidget {
  const NotificationLeading({
    super.key,
    required this.notification,
    this.tilt = 0,
  });

  static const size = 44.0;

  final AppNotification notification;

  /// Degrees: rows tilt their stamps a little, alternately.
  final double tilt;

  /// Whether the row starts with the capsule's photo (so the thumbnail on
  /// the right would only repeat it).
  static bool showsCapsulePhoto(AppNotification n) =>
      n.type == NotificationType.capsuleOpen && _photo(n) != null;

  static String? _photo(AppNotification n) {
    final url = n.thumbnailImageUrl;
    return url != null && url.startsWith('http') ? url : null;
  }

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final sender = n.fromUserId;
    switch (n.type) {
      case NotificationType.capsuleReady ||
          NotificationType.capsuleNearby ||
          NotificationType.newCountry:
        return const _Disc(child: _Pin());
      case NotificationType.capsuleOpen when _photo(n) != null:
        return ProfileStamp(
          style: const ProfileStampStyle(),
          size: size,
          photo: AppImageCache.provider(_photo(n)!, width: (size * 3).round()),
          tilt: tilt,
          elevation: 2,
        );
      case NotificationType.achievement:
        final def = AchievementCatalog.byId(n.achievementId ?? '');
        if (def == null) return const _Disc(child: _Logo());
        return AchievementIcon(
          id: def.id,
          icon: def.icon,
          tier: 0,
          tiers: def.tiers.length,
          size: size,
        );
      case _ when sender != null && sender.isNotEmpty:
        return UserStamp(userId: sender, size: size, tilt: tilt);
      case _:
        return const _Disc(child: _Logo());
    }
  }
}

/// A 44 dp circle on the soft green.
class _Disc extends StatelessWidget {
  const _Disc({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: NotificationLeading.size,
    height: NotificationLeading.size,
    alignment: Alignment.center,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: context.palette.accentSoft,
      shape: BoxShape.circle,
    ),
    child: child,
  );
}

class _Pin extends StatelessWidget {
  const _Pin();

  @override
  Widget build(BuildContext context) =>
      Image.asset(AppIcons.mapPin('green'), width: 26, height: 26);
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Image.asset(
    AppImages.laterLogo,
    width: NotificationLeading.size,
    height: NotificationLeading.size,
    fit: BoxFit.cover,
  );
}

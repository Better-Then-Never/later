import 'package:flutter/material.dart';
import 'package:later/app/router/app_routes.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';
import 'package:later/features/notifications/widgets/unread_notification_badge.dart';

class ProfilePageHeaderActionButtons extends StatelessWidget {
  const ProfilePageHeaderActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            DefaultIconButton(
              size: 44,
              assetPath: AppIcons.notifications,
              onTap: () => AppRoutes.toNotifications(context),
            ),
            const Positioned(
              right: 2,
              top: 2,
              child: UnreadNotificationBadge(size: 18),
            ),
          ],
        ),
        const SizedBox(width: 4),
        DefaultIconButton(
          size: 41,
          assetPath: AppIcons.share,
          onTap: () => AppRoutes.toShareProfile(context),
        ),
        const SizedBox(width: 5),
        DefaultIconButton(
          size: 41,
          assetPath: AppIcons.settings,
          onTap: () => AppRoutes.toSettings(context),
        ),
      ],
    );
  }
}

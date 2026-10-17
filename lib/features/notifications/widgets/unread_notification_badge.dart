import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/count_badge.dart';
import '../notifications_store.dart';

/// Number of unread notifications (hidden at 0).
class UnreadNotificationBadge extends StatelessWidget {
  const UnreadNotificationBadge({
    super.key,
    this.size = 20,
    this.badgeColor = AppColors.materialRed,
  });

  final double size;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.select<NotificationsStore, int>(
      (s) => s.unreadCount,
    );
    final hasUnread = unreadCount > 0;
    // Screen readers hear "3 unread notifications" in the app's language
    // instead of the badge's generic count.
    return Semantics(
      label: hasUnread
          ? context.l10n.notificationsUnreadBadge(unreadCount)
          : null,
      excludeSemantics: hasUnread,
      child: CountBadge(count: unreadCount, size: size, color: badgeColor),
    );
  }
}

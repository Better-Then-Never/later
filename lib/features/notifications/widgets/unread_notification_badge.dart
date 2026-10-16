import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_text_styles.dart';
import '../notifications_store.dart';

class UnreadNotificationBadge extends StatelessWidget {
  const UnreadNotificationBadge({
    super.key,
    this.size = 20,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
    this.textStyle,
  });

  final double size;
  final Color badgeColor;
  final Color textColor;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final unreadCount = context.select<NotificationsStore, int>(
      (s) => s.unreadCount,
    );
    if (unreadCount == 0) return const SizedBox.shrink();

    return Container(
      height: size,
      constraints: BoxConstraints(minWidth: size),
      decoration: BoxDecoration(
        color: badgeColor,
        shape: unreadCount > 9 ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: unreadCount > 9 ? BorderRadius.circular(size / 2) : null,
      ),
      padding: unreadCount > 9
          ? EdgeInsets.symmetric(horizontal: size * 0.35)
          : EdgeInsets.zero,
      alignment: Alignment.center,
      child: Text(
        unreadCount > 99 ? '99+' : unreadCount.toString(),
        style:
            textStyle ??
            TextStyle(
              color: textColor,
              fontSize: size * 0.6,
              fontWeight: FontWeight.bold,
              fontFamily: kAppFontFamily,
            ),
      ),
    );
  }
}

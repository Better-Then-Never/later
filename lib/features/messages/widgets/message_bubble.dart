import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../chat_time.dart';

/// One message: brand green on the right for the user's own, a white card on
/// the left for the friend's. Consecutive messages of one sender form a
/// group; [showTail] squares the bottom corner of the group's last bubble.
/// Capsule messages show the capsule's photo; tapping it calls
/// [onCapsuleTap]. A message still sending is shown at once; a failed one is
/// faded until it is retried.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showTail = false,
    this.onCapsuleTap,
  });

  final ChatMessage message;
  final bool isMine;
  final bool showTail;
  final VoidCallback? onCapsuleTap;

  static const _radius = Radius.circular(AppRadii.m);
  static const _tail = Radius.circular(6);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final textColor = isMine ? AppColors.textOnPrimary : AppColors.textPrimary;
    final imageUrl = message.imageUrl;
    final sentAt = message.sentAt;
    final failed = message.delivery == MessageDelivery.failed;

    final bubble = Container(
      padding: EdgeInsets.symmetric(
        horizontal: screen.width * 0.035,
        vertical: screen.height * 0.009,
      ),
      constraints: BoxConstraints(maxWidth: screen.width * 0.72),
      decoration: BoxDecoration(
        color: isMine ? AppColors.brandGreen : AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: _radius,
          topRight: _radius,
          bottomLeft: showTail && !isMine ? _tail : _radius,
          bottomRight: showTail && isMine ? _tail : _radius,
        ),
        boxShadow: isMine ? null : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.isCapsule) ...[
            if (imageUrl != null)
              Semantics(
                button: true,
                label: 'Open capsule ${message.text}',
                child: GestureDetector(
                  onTap: onCapsuleTap,
                  child: _CapsulePhoto(
                    imageUrl: imageUrl,
                    width: screen.width * 0.6,
                    height: screen.width * 0.45,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.text,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: screen.height * 0.02,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ] else
            Text(
              message.text,
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: screen.height * 0.022,
                color: textColor,
              ),
            ),
          if (sentAt != null) ...[
            const SizedBox(height: 2),
            Text(
              ChatTime.messageTime(sentAt),
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 11,
                color: isMine ? AppColors.white70 : AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(opacity: failed ? 0.5 : 1, child: bubble),
    );
  }
}

class _CapsulePhoto extends StatelessWidget {
  const _CapsulePhoto({
    required this.imageUrl,
    required this.width,
    required this.height,
  });

  final String imageUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.s),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppNetworkImage(url: imageUrl, cacheWidth: (width * 3).round()),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadii.lCircular,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(AppIcons.sendCapsule, width: 18, height: 18),
                    const SizedBox(width: 4),
                    const Text(
                      'Capsule',
                      style: TextStyle(
                        fontFamily: kAppFontFamily,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

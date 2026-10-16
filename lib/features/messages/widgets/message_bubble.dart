import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/chat.dart';
import '../chat_time.dart';

/// One message: green on the right for own messages, grey on the left for
/// the friend's. Capsule messages show the capsule's photo; tapping it calls
/// [onCapsuleTap].
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

  /// Squares the bottom corner of the last bubble of a group.
  final bool showTail;
  final VoidCallback? onCapsuleTap;

  static const _received = Color(0xFFE4E4E4);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final textColor = isMine ? Colors.white : Colors.black;
    final imageUrl = message.imageUrl;
    final sentAt = message.sentAt;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: screen.width * 0.04,
          vertical: screen.height * 0.005,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: screen.width * 0.04,
          vertical: screen.height * 0.010,
        ),
        constraints: BoxConstraints(maxWidth: screen.width * 0.7),
        decoration: BoxDecoration(
          color: isMine ? AppColors.brandGreen : _received,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(showTail && !isMine ? 4 : 20),
            bottomRight: Radius.circular(showTail && isMine ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.isCapsule) ...[
              if (imageUrl != null)
                GestureDetector(
                  onTap: onCapsuleTap,
                  child: _CapsulePhoto(
                    imageUrl: imageUrl,
                    width: screen.width * 0.6,
                    height: screen.width * 0.45,
                  ),
                ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: screen.height * 0.02,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ] else
              Text(
                message.text,
                style: TextStyle(
                  fontSize: screen.height * 0.025,
                  color: textColor,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sentAt != null)
                  Text(
                    ChatTime.messageTime(sentAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isMine ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                if (isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.white : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
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
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              cacheWidth: (width * 3).round(),
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandGreen,
                        strokeWidth: 2,
                      ),
                    ),
              errorBuilder: (_, _, _) => const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.all_inbox_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Capsule',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_image_service.dart';

class ChatListItem extends StatelessWidget {
  final String name;
  final String message;
  final String? friendId;
  final String? avatar;
  final DateTime? timestamp;
  final bool isPinned;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.name,
    required this.message,
    this.friendId,
    this.avatar,
    this.timestamp,
    this.isPinned = false,
    required this.onTap,
  });

  String _formatTimestamp(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(context),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (timestamp != null)
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isPinned)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Icon(
                    Icons.push_pin,
                    color: Colors.grey[700],
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (friendId != null) {
      final userImageService = context.read<UserImageService>();
      final profileNotifier = userImageService.getProfileNotifier(friendId!);

      return ValueListenableBuilder<ImageProvider>(
        valueListenable: profileNotifier,
        builder: (context, imageProvider, _) {
          return Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
            ),
          );
        },
      );
    }

    if (avatar != null && avatar!.isNotEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(avatar!, style: const TextStyle(fontSize: 32)),
        ),
      );
    }
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 32, color: Colors.white),
    );
  }
}

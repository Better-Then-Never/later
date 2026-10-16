import 'package:flutter/material.dart';

import '../../../shared/widgets/user/user_round_avatar.dart';
import '../chat_time.dart';

/// A row of the chat list: the friend's photo and name, the last message and
/// how long ago it was sent.
class ChatListItem extends StatelessWidget {
  const ChatListItem({
    super.key,
    required this.friendUid,
    required this.name,
    required this.message,
    required this.onTap,
    this.timestamp,
  });

  final String friendUid;
  final String name;
  final String message;
  final DateTime? timestamp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            UserRoundAvatar(userId: friendUid, radius: 30),
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
                          ChatTime.listLabel(timestamp, DateTime.now()),
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
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:later/data/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSentByMe;
  final DateTime? timestamp;
  final String? status;
  final bool showTail;
  final MessageType type;
  final String? imageUrl;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.timestamp,
    this.status,
    this.showTail = false,
    this.type = MessageType.text,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.005,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.010,
          ),
          constraints: BoxConstraints(maxWidth: screenWidth * 0.7),
          decoration: BoxDecoration(
            color: isSentByMe
                ? const Color(0xFF56C92E)
                : const Color(0xFFE4E4E4),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(showTail && !isSentByMe ? 4 : 20),
              bottomRight: Radius.circular(showTail && isSentByMe ? 4 : 20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (type == MessageType.capsule && imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(
                        imageUrl!,
                        width: screenWidth * 0.6,
                        height: screenWidth * 0.45,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            width: screenWidth * 0.6,
                            height: screenWidth * 0.45,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF56C92E),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => SizedBox(
                          width: screenWidth * 0.6,
                          height: screenWidth * 0.3,
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.all_inbox_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Capsule',
                                style: const TextStyle(
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
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: screenHeight * 0.02,
                      fontWeight: FontWeight.w600,
                      color: isSentByMe ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ] else ...[
                Text(
                  message,
                  style: TextStyle(
                    fontSize: screenHeight * 0.025,
                    color: isSentByMe ? Colors.white : Colors.black,
                  ),
                ),
              ],
              if (timestamp != null || (isSentByMe && status != null)) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (timestamp != null)
                      Text(
                        DateFormat('HH:mm').format(timestamp!),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSentByMe ? Colors.white70 : Colors.grey[500],
                        ),
                      ),
                    if (isSentByMe && status != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        status == 'read' ? Icons.done_all : Icons.done,
                        size: 14,
                        color: status == 'read' ? Colors.white : Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

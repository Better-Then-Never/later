import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isSentByMe;
  final DateTime? timestamp;
  final String? status;
  final bool showTail;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
    this.timestamp,
    this.status,
    this.showTail = false,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
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
          color: isSentByMe ? const Color(0xFF56C92E) : const Color(0xFFE4E4E4),
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
            Text(
              message,
              style: TextStyle(
                fontSize: screenHeight * 0.025,
                color: isSentByMe ? Colors.white : Colors.black,
              ),
            ),
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
    );
  }
}

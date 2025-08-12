import 'package:flutter/material.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/icons/message-page/write_new_message.png',
                    width: 36,
                    height: 36,
                  ),
                  Expanded(
                    child: Center(
                      child: const Text(
                        'My Latters',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Irina',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  // Add invisible spacer to balance the layout
                  SizedBox(width: 48), // Same width as icon + spacing
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: 'Find chats',
                    hintStyle: const TextStyle(
                      color: Color(0xFF5F5F5F),
                      fontFamily: 'Irina',
                      fontSize: 20,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/images/icons/message-page/search.png',
                        width: 29,
                        height: 29,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Chat List
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildChatItem(
                    name: 'Lorem ipsum',
                    message: 'Nulla consequat massa quis enim. Donec pede justo, fringilla vel, aliquet nec, vulputate eget, arcu.',
                    hasPin: true,
                  ),
                  _buildChatItem(
                    name: 'Donec quam',
                    message: 'Nullam dictum felis eu pede mollis pretium.',
                    hasPin: false,
                  ),
                  _buildChatItem(
                    name: 'Aenean vulputate',
                    message: 'Aliquam lorem ante, dapibus in, viverra quis, feugiat a, tellus.',
                    hasPin: false,
                  ),
                  
                  // No more chats message
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Text(
                        'No more chats',
                        style: TextStyle(
                          color: Color(0xFF000000),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Irina',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem({
    required String name,
    required String message,
    required bool hasPin,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/images/icons/message-page/avatar_placeholder.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Chat content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Irina',
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF757575),
                    fontFamily: 'Irina',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Pin icon and arrow
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasPin) ...[
                Image.asset(
                  'assets/images/icons/message-page/pinned_chat.png',
                  width: 20,
                  height: 20,
                ),
                const SizedBox(width: 12),
              ],
              Transform.rotate(
                angle: 3.14159, // 180 degrees in radians (π)
                child: Image.asset(
                  'assets/images/icons/message-page/black_arrow.png',
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

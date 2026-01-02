import 'package:flutter/material.dart';
import 'package:later/views/pages/messages_pages/private_message_page.dart';
import 'package:later/views/widgets/messages/messages_header.dart';
import 'package:later/views/widgets/messages/chat_list_item.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final TextEditingController _searchController = TextEditingController();

  // TODO: Replace with a real data
  final List<Map<String, dynamic>> _placeholderChats = [
    {
      'name': 'Xerox Aksejshtwelve',
      'message': 'Ja pierdolę, co to byto, kurwa...',
      'avatar': '😺',
      'isPinned': true,
    },
    {
      'name': 'Uncle Dodik',
      'message': 'Sławomir Rudziński znów je g...',
      'avatar': '🦦',
      'isPinned': false,
    },
    {
      'name': 'Umbrella Down',
      'message': 'O kurwa, to był skebob tam!',
      'avatar': '🌂',
      'isPinned': false,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            MessagesHeader(
              searchController: _searchController,
              onSearchChanged: (value) {
                // TODO: Implement search functionality
                setState(() {});
              },
            ),
            Expanded(child: _buildChatList()),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      itemCount: _placeholderChats.length + 1,
      itemBuilder: (context, index) {
        if (index == _placeholderChats.length) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No more chats',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
          );
        }

        final chat = _placeholderChats[index];
        return ChatListItem(
          name: chat['name'],
          message: chat['message'],
          avatar: chat['avatar'],
          isPinned: chat['isPinned'],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivateMessagePage(),
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:later/views/pages/messages_pages/private_message_page.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PrivateMessagePage()),
          );
        },
        child: const Text('Open Private Message'),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:later/views/widgets/messages/message_bubble.dart';
import 'package:later/views/widgets/messages/message_input.dart';

class PrivateMessagePage extends StatefulWidget {
  const PrivateMessagePage({super.key});

  @override
  State<PrivateMessagePage> createState() => _PrivateMessagePageState();
}

class _PrivateMessagePageState extends State<PrivateMessagePage> {
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Co?', 'isSentByMe': false},
    {'text': 'Spierdalaj!', 'isSentByMe': true},
  ];

  void _handleSendMessage(String message) {
    setState(() {
      _messages.add({'text': message, 'isSentByMe': true});
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.01,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  IconButton(
                    icon: Image.asset(
                      'assets/images/icons/private_message_page/header/go_back.png',
                      height: screenHeight * 0.05,
                      width: screenHeight * 0.05,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  SizedBox(width: screenWidth * 0.04),

                  // Profile Picture
                  CircleAvatar(
                    radius: screenHeight * 0.025,
                    backgroundImage: const AssetImage(
                      'assets/images/icons/private_message_page/header/friend_placeholder.png',
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.04),

                  Expanded(
                    child: Text(
                      "Uncle Dodik",
                      style: TextStyle(
                        fontSize: screenHeight * 0.03,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  IconButton(
                    icon: Image.asset(
                      'assets/images/icons/private_message_page/header/menu.png',
                      height: screenHeight * 0.075,
                      width: screenHeight * 0.075,
                    ),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return MessageBubble(
                  message: message['text'],
                  isSentByMe: message['isSentByMe'],
                );
              },
            ),
          ),

          // Message Input
          MessageInput(onSendMessage: _handleSendMessage),
        ],
      ),
    );
  }
}

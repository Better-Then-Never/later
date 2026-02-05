import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_search_bar.dart';
import 'package:later/views/widgets/messages/friends_picker.dart';

class MessagesHeader extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;

  const MessagesHeader({
    super.key,
    required this.searchController,
    this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
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
        child: Column(
          children: [
            Stack(
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.01,
                    ),
                    child: Text(
                      "My Latters",
                      style: TextStyle(
                        fontSize: screenHeight * 0.03,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  child: IconButton(
                    icon: Image.asset(
                      'assets/images/icons/messages_page/header/write_new_message.png',
                      height: screenHeight * 0.05,
                      width: screenHeight * 0.05,
                    ),
                    onPressed: () {
                      FriendsPicker.show(context);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.01),
            DefaultSearchBar(
              controller: searchController,
              hintText: 'Find chats',
              onChanged: onSearchChanged,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';
import '../../../shared/widgets/default_search_bar.dart';

/// "My Laters" header of the chat list: new-chat button and chat search.
class MessagesHeader extends StatelessWidget {
  const MessagesHeader({
    super.key,
    required this.searchController,
    required this.onNewChat,
    this.onSearchChanged,
  });

  final TextEditingController searchController;
  final VoidCallback onNewChat;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screen.width * 0.03,
        vertical: screen.height * 0.01,
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
                      vertical: screen.height * 0.01,
                    ),
                    child: Text(
                      'My Laters',
                      style: TextStyle(
                        fontSize: screen.height * 0.03,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  child: IconButton(
                    tooltip: 'New chat',
                    icon: Image.asset(
                      AppIcons.messagesNew,
                      height: screen.height * 0.05,
                      width: screen.height * 0.05,
                    ),
                    onPressed: onNewChat,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
            SizedBox(height: screen.height * 0.01),
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

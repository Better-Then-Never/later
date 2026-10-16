import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/chat.dart';
import '../users/user_directory.dart';
import 'chats_store.dart';
import 'widgets/chat_list_item.dart';
import 'widgets/messages_header.dart';
import 'widgets/new_chat_sheet.dart';

/// The "Messages" tab: the user's chats, newest first, with search.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _searchController = TextEditingController();
  String _query = '';

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
              onNewChat: () => NewChatSheet.show(context),
              onSearchChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
            Expanded(child: _ChatList(query: _query)),
          ],
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChatsStore>();
    final directory = context.watch<UserDirectory>();
    final me = store.uid ?? '';

    if (!store.isLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brandGreen),
      );
    }
    if (store.hasError) {
      return _Info(
        icon: Icons.error_outline,
        title: 'Failed to load chats',
        action: TextButton(onPressed: store.retry, child: const Text('Retry')),
      );
    }
    if (store.chats.isEmpty) {
      return const _Info(
        icon: Icons.chat_bubble_outline,
        title: 'No conversations yet',
        subtitle: 'Tap the new message button to start chatting with friends!',
      );
    }

    bool matches(Chat chat) {
      if (query.isEmpty) return true;
      final friend = directory.profile(chat.otherThan(me));
      return chat.lastMessage.toLowerCase().contains(query) ||
          (friend?.name.toLowerCase().contains(query) ?? false) ||
          (friend?.username.toLowerCase().contains(query) ?? false);
    }

    final chats = store.chats.where(matches).toList();
    return ListView.builder(
      itemCount: chats.length + 1,
      itemBuilder: (context, index) {
        if (index == chats.length) {
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
        final chat = chats[index];
        final friendUid = chat.otherThan(me);
        return ChatListItem(
          key: ValueKey(chat.id),
          friendUid: friendUid,
          name: directory.profile(friendUid)?.name ?? '',
          message: chat.lastMessage,
          timestamp: chat.lastUpdated,
          onTap: friendUid.isEmpty
              ? () {}
              : () => AppRoutes.toChat(context, friendUid),
        );
      },
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
            ?action,
          ],
        ),
      ),
    );
  }
}

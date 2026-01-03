import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/services/chat_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/data/models/chat.dart';
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
  final Map<String, Map<String, String>> _userDataCache = {};
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _getUserData(String friendId) async {
    if (_userDataCache.containsKey(friendId)) {
      return _userDataCache[friendId]!;
    }

    final userDataService = context.read<UserDataService>();
    final data = await userDataService.getUserData(friendId);
    _userDataCache[friendId] = data;
    return data;
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
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
            Expanded(child: _buildChatList()),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    final chatService = context.read<ChatService>();

    return StreamBuilder<List<Chat>>(
      stream: chatService.getUserChatsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF56C92E)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load chats',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final chats = snapshot.data ?? [];

        if (chats.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          itemCount: chats.length + 1,
          itemBuilder: (context, index) {
            if (index == chats.length) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    chats.isEmpty ? '' : 'No more chats',
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
            return _ChatListItemBuilder(
              chat: chat,
              chatService: chatService,
              searchQuery: _searchQuery,
              getUserData: _getUserData,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the new message button to start chatting with friends!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatListItemBuilder extends StatefulWidget {
  final Chat chat;
  final ChatService chatService;
  final String searchQuery;
  final Future<Map<String, String>> Function(String) getUserData;

  const _ChatListItemBuilder({
    required this.chat,
    required this.chatService,
    required this.searchQuery,
    required this.getUserData,
  });

  @override
  State<_ChatListItemBuilder> createState() => _ChatListItemBuilderState();
}

class _ChatListItemBuilderState extends State<_ChatListItemBuilder> {
  Map<String, String>? _friendData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendData();
  }

  Future<void> _loadFriendData() async {
    final currentUserId = widget.chatService.currentUserId ?? '';
    final friendId = widget.chat.getOtherParticipantId(currentUserId);

    if (friendId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final data = await widget.getUserData(friendId);
    if (mounted) {
      setState(() {
        _friendData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 84,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF56C92E),
            ),
          ),
        ),
      );
    }

    final currentUserId = widget.chatService.currentUserId ?? '';
    final friendId = widget.chat.getOtherParticipantId(currentUserId);
    final name = _friendData?['name'] ?? 'Unknown';
    final username = _friendData?['username'] ?? '';

    if (widget.searchQuery.isNotEmpty) {
      final matchesName = name.toLowerCase().contains(widget.searchQuery);
      final matchesUsername = username.toLowerCase().contains(
        widget.searchQuery,
      );
      final matchesMessage = widget.chat.lastMessage.toLowerCase().contains(
        widget.searchQuery,
      );

      if (!matchesName && !matchesUsername && !matchesMessage) {
        return const SizedBox.shrink();
      }
    }

    return ChatListItem(
      name: name,
      message: widget.chat.lastMessage.isEmpty
          ? 'Start a conversation'
          : widget.chat.lastMessage,
      friendId: friendId,
      timestamp: widget.chat.lastUpdated,
      isPinned: false,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PrivateMessagePage(chatId: widget.chat.id, friendId: friendId),
          ),
        );
      },
    );
  }
}

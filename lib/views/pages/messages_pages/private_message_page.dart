import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:later/services/chat_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/user_image_service.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/data/models/chat_message.dart';
import 'package:later/views/widgets/messages/message_bubble.dart';
import 'package:later/views/widgets/messages/message_input.dart';
import 'package:later/views/widgets/messages/chat_options_modal.dart';
import 'package:later/views/widgets/map/opened_capsule_widget.dart';
import 'package:intl/intl.dart';

class PrivateMessagePage extends StatefulWidget {
  final String chatId;
  final String friendId;

  const PrivateMessagePage({
    super.key,
    required this.chatId,
    required this.friendId,
  });

  @override
  State<PrivateMessagePage> createState() => _PrivateMessagePageState();
}

class _PrivateMessagePageState extends State<PrivateMessagePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Map<String, String> _friendData = {};
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isBlockedByFriend = false;
  bool _showScrollToBottom = false;
  late final Stream<List<ChatMessage>> _messagesStream;
  bool _hasMarkedAsRead = false;

  @override
  void initState() {
    super.initState();
    final chatService = context.read<ChatService>();
    _messagesStream = chatService.getMessagesStream(widget.chatId);
    _loadFriendData();
    _markMessagesAsRead();
    _checkBlockedByFriend();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = 100.0;

    final shouldShow = (maxScroll - currentScroll) > threshold;

    if (shouldShow != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = shouldShow;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  Future<void> _loadFriendData() async {
    try {
      final userDataService = context.read<UserDataService>();
      final data = await userDataService.getUserData(widget.friendId);
      if (mounted) {
        setState(() {
          _friendData = data;
        });
      }
    } catch (e) {}
  }

  Future<void> _checkBlockedByFriend() async {
    final userFriendsService = context.read<UserFriendsService>();
    final blocked = await userFriendsService.isBlockedByUser(widget.friendId);
    if (mounted) {
      setState(() {
        _isBlockedByFriend = blocked;
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    final chatService = context.read<ChatService>();
    await chatService.markMessagesAsRead(widget.chatId);
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    try {
      final chatService = context.read<ChatService>();
      await chatService.sendMessage(widget.chatId, text, widget.friendId);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendCapsuleToFriend() {
    Navigator.pushNamed(
      context,
      '/camera',
      arguments: {'privacy': 'private', 'recipientId': widget.friendId},
    );
  }

  Future<void> _openCapsule(String capsuleId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('capsules')
          .doc(capsuleId)
          .get();

      if (!doc.exists || !mounted) return;

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;

      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: CapsulePreviewCard(capsuleData: data),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load capsule'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = context.read<ChatService>();
    final userImageService = context.read<UserImageService>();
    final userFriendsService = context.watch<UserFriendsService>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final friendName = _friendData['name'] ?? 'Chat';
    final iBlockedThem = userFriendsService.isBlocked(widget.friendId);
    final isBlocked = iBlockedThem || _isBlockedByFriend;
    final profileNotifier = userImageService.getProfileNotifier(
      widget.friendId,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
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
                  ValueListenableBuilder<ImageProvider>(
                    valueListenable: profileNotifier,
                    builder: (context, imageProvider, _) {
                      return CircleAvatar(
                        radius: screenHeight * 0.025,
                        backgroundImage: imageProvider,
                      );
                    },
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: Text(
                      friendName,
                      style: TextStyle(
                        fontSize: screenHeight * 0.025,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Image.asset(
                      'assets/images/icons/private_message_page/header/menu.png',
                      height: screenHeight * 0.075,
                      width: screenHeight * 0.075,
                    ),
                    onPressed: () {
                      ChatOptionsModal.show(
                        context,
                        chatId: widget.chatId,
                        friendUid: widget.friendId,
                        onSearch: _toggleSearch,
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          if (_isSearching)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: 8,
              ),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 15, fontFamily: 'Irina'),
                      decoration: InputDecoration(
                        hintText: 'Search messages...',
                        hintStyle: TextStyle(
                          fontSize: 15,
                          fontFamily: 'Irina',
                          color: Colors.grey[400],
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF6F6F6),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _toggleSearch,
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Irina',
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<List<ChatMessage>>(
                  stream: _messagesStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF56C92E),
                        ),
                      );
                    }

                    final allMessages = snapshot.data ?? [];
                    final messages = _searchQuery.isEmpty
                        ? allMessages
                        : allMessages
                              .where(
                                (m) =>
                                    m.text.toLowerCase().contains(_searchQuery),
                              )
                              .toList();

                    if (allMessages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Say hello to $friendName!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (!_hasMarkedAsRead) {
                      _hasMarkedAsRead = true;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _markMessagesAsRead();
                      });
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      cacheExtent: 500,
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.04,
                        vertical: 16,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe =
                            message.senderId == chatService.currentUserId;
                        final showDate =
                            index == 0 ||
                            !_isSameDay(
                              messages[index - 1].timestamp,
                              message.timestamp,
                            );

                        final isLastInGroup =
                            index == messages.length - 1 ||
                            messages[index + 1].senderId != message.senderId ||
                            !_isSameDay(
                              message.timestamp,
                              messages[index + 1].timestamp,
                            );

                        return Column(
                          key: ValueKey(message.id),
                          children: [
                            if (showDate)
                              _buildDateSeparator(message.timestamp),
                            MessageBubble(
                              message: message.text,
                              isSentByMe: isMe,
                              timestamp: message.timestamp,
                              status: message.status,
                              showTail: isLastInGroup,
                              type: message.type,
                              imageUrl: message.imageUrl,
                              onTap:
                                  message.type == MessageType.capsule &&
                                      message.capsuleId != null
                                  ? () => _openCapsule(message.capsuleId!)
                                  : null,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                if (_showScrollToBottom)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _scrollToBottom,
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Color(0xFF56C92E),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (isBlocked)
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    iBlockedThem
                        ? 'You blocked this user'
                        : "You can't send messages to this user",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Irina',
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            )
          else
            MessageInput(
              onSendMessage: _sendMessage,
              onCapsuleTap: _sendCapsuleToFriend,
            ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateSeparator(DateTime? timestamp) {
    String dateText;
    if (timestamp == null) {
      dateText = 'Today';
    } else {
      final now = DateTime.now();
      if (_isSameDay(timestamp, now)) {
        dateText = 'Today';
      } else if (_isSameDay(timestamp, now.subtract(const Duration(days: 1)))) {
        dateText = 'Yesterday';
      } else {
        dateText = DateFormat('MMMM d, yyyy').format(timestamp);
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}

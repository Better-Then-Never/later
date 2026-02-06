import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/user_image_service.dart';
import 'package:later/services/chat_service.dart';
import 'package:later/views/pages/messages_pages/private_message_page.dart';

class FriendsPicker extends StatefulWidget {
  const FriendsPicker({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (context) => const FriendsPicker(),
    );
  }

  @override
  State<FriendsPicker> createState() => _FriendsPickerState();
}

class _FriendsPickerState extends State<FriendsPicker> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Map<String, String>> _friendsData = {};
  bool _isLoading = true;
  bool _isCreatingChat = false;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final friendsService = context.read<UserFriendsService>();
      final userDataService = context.read<UserDataService>();

      final friendIds = friendsService.friends.toList();

      await Future.wait(
        friendIds.map((id) async {
          final data = await userDataService.getUserData(id);
          _friendsData[id] = data;
        }),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load friends. Tap to retry.';
        });
      }
    }
  }

  List<MapEntry<String, Map<String, String>>> get _filteredFriends {
    if (_searchQuery.isEmpty) {
      return _friendsData.entries.toList();
    }

    final query = _searchQuery.toLowerCase();
    return _friendsData.entries.where((entry) {
      final name = entry.value['name']?.toLowerCase() ?? '';
      final username = entry.value['username']?.toLowerCase() ?? '';
      return name.contains(query) || username.contains(query);
    }).toList();
  }

  Future<void> _onFriendTap(String friendId) async {
    if (_isCreatingChat) return;

    setState(() {
      _isCreatingChat = true;
    });

    try {
      final chatService = context.read<ChatService>();
      final chatId = chatService.getChatId(friendId);

      if (!mounted) return;

      Navigator.of(context).pop();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              PrivateMessagePage(chatId: chatId, friendId: friendId),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingChat = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: screenHeight * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.02,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Text(
                  'New Chat',
                  style: TextStyle(
                    fontSize: screenHeight * 0.025,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Irina',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEAEAEA),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Icon(
                      Icons.search,
                      color: Colors.grey[600],
                      size: screenWidth * 0.06,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search friends',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(fontFamily: 'Irina', fontSize: 18),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: screenHeight * 0.02),

          Expanded(child: _buildContent(screenHeight, screenWidth)),
        ],
      ),
    );
  }

  Widget _buildContent(double screenHeight, double screenWidth) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF56C92E)),
      );
    }

    if (_error != null) {
      return Center(
        child: GestureDetector(
          onTap: _loadFriends,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_friendsData.isEmpty) {
      return _buildEmptyState(screenHeight, screenWidth);
    }

    final friends = _filteredFriends;

    if (friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No friends match "$_searchQuery"',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friend = friends[index];
            return _FriendListItem(
              friendId: friend.key,
              friendData: friend.value,
              onTap: () => _onFriendTap(friend.key),
            );
          },
        ),
        if (_isCreatingChat)
          Container(
            color: Colors.white.withAlpha(178),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF56C92E)),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(double screenHeight, double screenWidth) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No friends yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some friends to start chatting!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/add_friends');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF56C92E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Find Friends',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendListItem extends StatelessWidget {
  final String friendId;
  final Map<String, String> friendData;
  final VoidCallback onTap;

  const _FriendListItem({
    required this.friendId,
    required this.friendData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final userImageService = context.read<UserImageService>();
    final profileNotifier = userImageService.getProfileNotifier(friendId);

    final name = friendData['name'] ?? 'Unknown';
    final username = friendData['username'] ?? '';

    return Semantics(
      label: 'Start chat with $name',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              ValueListenableBuilder<ImageProvider>(
                valueListenable: profileNotifier,
                builder: (context, imageProvider, _) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: screenHeight * 0.02,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (username.isNotEmpty)
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: screenHeight * 0.016,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

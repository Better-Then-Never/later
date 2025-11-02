import 'package:flutter/material.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/pages/friends_pages/add_friend_profile_page.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/friends/add_friends_page/suggested_friend_placeholder_row.dart';
import 'package:later/views/widgets/friends/add_friends_page/suggested_friend_row.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/user_image_service.dart';

class SuggestedFriendsList extends StatefulWidget {
  final Function(String userId) onSendRequest;
  final Function(String userId) onRemoveFriend;
  final String searchQuery;

  const SuggestedFriendsList({
    super.key,
    required this.onSendRequest,
    required this.onRemoveFriend,
    this.searchQuery = '',
  });

  @override
  State<SuggestedFriendsList> createState() => _SuggestedFriendsListState();
}

class _SuggestedFriendsListState extends State<SuggestedFriendsList>
    with AutomaticKeepAliveClientMixin<SuggestedFriendsList> {
  /// Users that are fully loaded and ready to display
  final Map<String, Map<String, dynamic>> _readyUsers = {};

  /// Users still loading (either data or avatar)
  final Set<String> _loadingUserIds = {};
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userService = context.read<UserDataService>();
    final userFriendsService = context.watch<UserFriendsService>();
    final imageService = context.read<UserImageService>();
    final currentUid = userService.currentLoggedInUid;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userFriendsService.getSuggestedFriends(
        currentUserId: currentUid,
        searchQuery: widget.searchQuery,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center();

        final users = snapshot.data!;
        if (users.isEmpty) {
          return const Center(child: DefaultText('No more suggested friends'));
        }

        for (var user in users) {
          final userId = user['id'] ?? '';
          if (!_readyUsers.containsKey(userId) &&
              !_loadingUserIds.contains(userId)) {
            _loadUser(userId, userService, imageService);
          }
        }

        return ListView(
          children: [
            for (var userData in _readyUsers.values)
              _buildUserRow(context, userData, userFriendsService),
            for (var user in users)
              if (!_readyUsers.containsKey(user['id']))
                SuggestedFriendPlaceholderRow(
                  screenWidth: MediaQuery.of(context).size.width,
                ),
          ],
        );
      },
    );
  }

  /// Load user data and profile image, then mark as ready
  void _loadUser(
    String userId,
    UserDataService userService,
    UserImageService imageService,
  ) async {
    if (_loadingUserIds.contains(userId)) return;
    _loadingUserIds.add(userId);

    try {
      final userData = await userService.getUserData(userId);
      final profileNotifier = imageService.getProfileNotifier(userId);

      // Helper to mark the user as ready
      Future<void> markUserReady() async {
        final imageProvider = profileNotifier.value;

        if (imageProvider is NetworkImage) {
          await precacheImage(imageProvider, context);

          if (mounted) {
            setState(() {
              _readyUsers[userId] = userData;
              _loadingUserIds.remove(userId);
            });
          }
        }
      }

      if (profileNotifier.value is NetworkImage) {
        // Image already loaded, mark user immediately
        await markUserReady();
      } else {
        // Wait for image to load
        void listener() async {
          await markUserReady();
          profileNotifier.removeListener(listener);
        }

        profileNotifier.addListener(listener);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingUserIds.remove(userId);
        });
      }
    }
  }

  Widget _buildUserRow(
    BuildContext context,
    Map<String, dynamic> userData,
    UserFriendsService userFriendsService,
  ) {
    final userId = userData['id'] ?? '';
    final isSent = userFriendsService.sentRequests.contains(userId);

    return SuggestedFriendRow(
      userId: userId,
      name: userData['name'] ?? '',
      username: userData['username'] ?? '',
      onTapProfile: () {
        Navigator.push(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            duration: const Duration(milliseconds: 10),
            reverseDuration: const Duration(milliseconds: 10),
            child: AddFriendProfilePage(userId: userId),
          ),
        );
      },
      onSendRequest: () => widget.onSendRequest(userId),
      onRemove: () => widget.onRemoveFriend(userId),
      isSent: isSent,
      screenWidth: MediaQuery.of(context).size.width,
    );
  }
}

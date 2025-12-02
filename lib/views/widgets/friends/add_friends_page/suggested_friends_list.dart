import 'package:flutter/material.dart';
import 'package:later/controllers/widget_controllers/friends/suggested_friends_list_controller.dart';
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
  late SuggestedFriendsListController controller;

  @override
  void initState() {
    super.initState();
    final userService = context.read<UserDataService>();
    final imageService = context.read<UserImageService>();

    controller = SuggestedFriendsListController(
      userService: userService,
      imageService: imageService,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final userFriendsService = context.watch<UserFriendsService>();
    final currentUid = context.read<UserDataService>().currentLoggedInUid;

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
          if (!controller.readyUsers.containsKey(userId) &&
              !controller.loadingUserIds.contains(userId)) {
            controller.loadUser(userId, () {
              if (mounted) setState(() {});
            });
          }
        }

        return ListView(
          children: [
            for (var userData in controller.readyUsers.values)
              if (!controller.removedUserIds.contains(userData['id']))
                _buildUserRow(context, userData, userFriendsService),

            for (var user in users)
              if (!controller.readyUsers.containsKey(user['id']) &&
                  !controller.removedUserIds.contains(user['id']))
                SuggestedFriendPlaceholderRow(
                  screenWidth: MediaQuery.of(context).size.width,
                ),
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

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
      onRemove: () {
        widget.onRemoveFriend(userId);
        controller.removeUser(userId, () {
          if (mounted) setState(() {});
        });
      },
      isSent: isSent,
      screenWidth: MediaQuery.of(context).size.width,
    );
  }
}

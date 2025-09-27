import 'package:flutter/material.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/widgets/friends/add_friends_page/suggested_friend_row.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/views/pages/friends_pages/add_friend_profile_page.dart';

class SuggestedFriendsList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final userService = Provider.of<UserDataService>(context);
    final userFriendsService = Provider.of<UserFriendsService>(context);
    final currentUid = userService.currentLoggedInUid;
    final screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userFriendsService.getSuggestedFriends(
        currentUserId: currentUid,
        searchQuery: searchQuery,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!;
        if (users.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 180),
            child: Center(
              child: Text(
                'No more suggested friends',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                  color: Colors.black,
                ),
              ),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: users.map((user) {
            final isSent = userFriendsService.sentRequests.contains(user['id']);
            return Column(
              children: [
                SuggestedFriendRow(
                  userId: user['id'],
                  name: user['name'],
                  username: user['username'],
                  onTapProfile: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddFriendProfilePage(userId: user['id']),
                      ),
                    );
                  },
                  onSendRequest: () => onSendRequest(user['id']),
                  onRemove: () => onRemoveFriend(user['id']),
                  isSent: isSent,
                  screenWidth: screenWidth,
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFD3D3D3),
                ),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

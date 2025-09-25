import 'package:flutter/material.dart';
import 'package:later/services/user_data_service.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/views/pages/friends_pages/add_friend_profile_page.dart';
import 'package:later/services/image_assets_service.dart';
import 'package:later/views/widgets/friends/suggested_friends_list/suggested_friend_row.dart';

class SuggestedFriendsList extends StatelessWidget {
  final Function(String userId) onSendRequest;
  final Function(String userId) onRemoveFriend;
  final Set<String> hiddenUserIds;
  final Set<String> sentRequestIds;
  final String searchQuery;
  final VoidCallback? onStateChanged;

  final UserFriendsService _requestService = UserFriendsService();

  SuggestedFriendsList({
    super.key,
    required this.onSendRequest,
    required this.onRemoveFriend,
    required this.hiddenUserIds,
    required this.sentRequestIds,
    required this.searchQuery,
    this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserDataService>(context);
    final userFriendsService = Provider.of<UserFriendsService>(context);
    final assetImageService = AssetImageService();

    final currentUid = userService.currentLoggedInUid;
    final screenWidth = MediaQuery.of(context).size.width;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: userFriendsService.getSuggestedFriends(
        currentUserId: currentUid,
        hiddenUserIds: hiddenUserIds,
        searchQuery: searchQuery,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data!;
        if (users.isEmpty) {
          return Padding(
            padding: EdgeInsets.only(top: 180),
            child: Align(
              alignment: Alignment.center,
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

        return Container(
          width: screenWidth * 0.92,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                spreadRadius: 0,
                blurRadius: 9,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < users.length; i++) ...[
                SuggestedFriendRow(
                  userId: users[i]['id']!,
                  name: users[i]['name']!,
                  username: users[i]['username']!,
                  avatarFuture: assetImageService.getProfileImageUrl(
                    users[i]['id']!,
                  ),
                  onTapProfile: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFriendProfilePage(
                          userId: users[i]['id']!,
                          onStateChanged: onStateChanged,
                        ),
                      ),
                    );
                  },
                  onSendRequest: () => onSendRequest(users[i]['id']!),
                  onRemove: () => onRemoveFriend(users[i]['id']!),
                  isSent: sentRequestIds.contains(users[i]['id']!),
                  screenWidth: screenWidth,
                  requestService: _requestService,
                  currentUid: currentUid,
                  onStateChanged: onStateChanged,
                ),
                if (i < users.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 0,
                    endIndent: 0,
                    color: Color.fromARGB(255, 211, 211, 211),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

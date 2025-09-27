import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'friend_requests_sent_row.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/controllers/friend_requests_page_controller.dart';
import 'package:later/views/widgets/_common/default_elements/default_empty_inbox_info.dart';

class FriendRequestsSentList extends StatelessWidget {
  final double screenWidth;
  final FriendRequestsPageController controller;
  final UserDataService userDataService;

  const FriendRequestsSentList({
    super.key,
    required this.screenWidth,
    required this.controller,
    required this.userDataService,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserFriendsService>(
      builder: (context, friendsService, child) {
        final sentRequests = friendsService.sentRequests.toList();

        if (sentRequests.isEmpty) {
          return const DefaultEmptyInboxInfo(
            message: 'No sent requests',
            subtitle: 'Friend requests you send\nwill appear here',
            assetPath:
                'assets/images/icons/friends_page/friend_request_page.png',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: sentRequests.length,
          itemBuilder: (context, index) {
            final toUserId = sentRequests[index];
            return FutureBuilder<Map<String, dynamic>>(
              future: userDataService.getUserData(toUserId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final userData = snapshot.data!;
                final name = userData['name'] ?? 'Unknown User';
                final username = userData['username'] ?? 'unknown';

                return FriendRequestsSentRow(
                  uid: toUserId,
                  name: name,
                  username: username,
                  screenWidth: screenWidth,
                  onCancel: () => controller.cancelFriendRequest(
                    userId: toUserId,
                    context: context,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

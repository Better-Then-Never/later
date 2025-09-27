import 'package:flutter/material.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:provider/provider.dart';
import 'friend_requests_received_row.dart';
import 'package:later/controllers/friend_requests_page_controller.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/widgets/_common/default_elements/default_empty_inbox_info.dart';

class FriendRequestsReceivedList extends StatelessWidget {
  final double screenWidth;
  final FriendRequestsPageController controller;
  final UserDataService userDataService;

  const FriendRequestsReceivedList({
    super.key,
    required this.screenWidth,
    required this.controller,
    required this.userDataService,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<UserFriendsService>(
      builder: (context, friendsService, child) {
        final receivedRequests = friendsService.receivedRequests.toList();

        if (receivedRequests.isEmpty) {
          return const DefaultEmptyInboxInfo(
            message: 'No friend requests',
            subtitle:
                'When someone sends you a friend request,\nit will appear here',
            assetPath:
                'assets/images/icons/friends_page/friend_request_page.png',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: receivedRequests.length,
          itemBuilder: (context, index) {
            final fromUserId = receivedRequests[index];

            return FutureBuilder<Map<String, dynamic>>(
              future: userDataService.getUserData(fromUserId),
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

                return FriendRequestsReceivedRow(
                  uid: fromUserId,
                  name: name,
                  username: username,
                  screenWidth: screenWidth,
                  onAccept: () => controller.acceptRequest(
                    fromUserId: fromUserId,
                    context: context,
                  ),
                  onReject: () => controller.rejectRequest(
                    fromUserId: fromUserId,
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

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:later/views/widgets/_common/default_elements/default_loading_container.dart';
import 'package:later/views/widgets/user/user_avatar.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/firebase_storage_service.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/views/pages/friends_pages/friend_accept_reject_page.dart';
import 'package:later/services/user_data_service.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  late final UserFriendsService _userFriendsService;
  late final UserDataService _userDataService;

  bool _showReceived = true;
  bool _hasAcceptedRequest = false;
  bool _hasCancelledRequest = false;

  @override
  void initState() {
    super.initState();
    _userFriendsService = Provider.of<UserFriendsService>(
      context,
      listen: false,
    );

    _userDataService = Provider.of<UserDataService>(context, listen: false);
  }

  @override
  void dispose() {
    PopupNotificationService.hide();
    super.dispose();
  }

  Widget _buildReceivedRequestsWidget(double screenWidth) {
    return StreamBuilder<QuerySnapshot>(
      stream: UserFriendsService.getReceivedRequests(
        _userDataService.currentLoggedInUid,
      ),
      builder: (context, snapshot) {
        return _buildStreamContent(
          snapshot: snapshot,
          screenWidth: screenWidth,
          emptyMessage: 'No friend requests',
          emptySubtitle:
              'When someone sends you a friend request,\nit will appear here',
          loadingMessage: 'Loading friend requests...',
          errorMessage: 'Error loading friend requests',
          itemBuilder: (request) =>
              _buildReceivedRequestItem(request, screenWidth),
        );
      },
    );
  }

  Widget _buildSentRequestsWidget(double screenWidth) {
    return StreamBuilder<QuerySnapshot>(
      stream: UserFriendsService.getSentRequests(
        _userDataService.currentLoggedInUid,
      ),
      builder: (context, snapshot) {
        return _buildStreamContent(
          snapshot: snapshot,
          screenWidth: screenWidth,
          emptyMessage: 'No sent requests',
          emptySubtitle: 'Friend requests you send\nwill appear here',
          loadingMessage: 'Loading sent requests...',
          errorMessage: 'Error loading sent requests',
          itemBuilder: (request) =>
              _buildSentRequestItem(request, screenWidth, _userDataService),
        );
      },
    );
  }

  Widget _buildStreamContent({
    required AsyncSnapshot<QuerySnapshot> snapshot,
    required double screenWidth,
    required String emptyMessage,
    required String emptySubtitle,
    required String loadingMessage,
    required String errorMessage,
    required Widget Function(QueryDocumentSnapshot) itemBuilder,
  }) {
    if (snapshot.hasError) {
      return _buildErrorWidget(errorMessage, screenWidth);
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildLoadingWidget(loadingMessage, screenWidth);
    }

    if (!snapshot.hasData) {
      return Center(child: CircularProgressIndicator());
    }

    final requests = snapshot.data!.docs;

    if (requests.isEmpty) {
      return _buildEmptyWidget(emptyMessage, emptySubtitle, screenWidth);
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) => itemBuilder(requests[index]),
    );
  }

  Widget _buildErrorWidget(String message, double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Color.fromARGB(255, 253, 65, 64),
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              fontFamily: 'Irina',
              color: Color.fromARGB(255, 253, 65, 64),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontFamily: 'Irina',
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(String message, double screenWidth) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontFamily: 'Irina',
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(
    String message,
    String subtitle,
    double screenWidth,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/icons/friends_page/friend_request_page.png',
            width: 72,
            height: 72,
          ),
          SizedBox(height: 5),
          Text(
            message,
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.bold,
              fontFamily: 'Irina',
              color: Colors.black,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontFamily: 'Irina',
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivedRequestItem(
    QueryDocumentSnapshot request,
    double screenWidth,
  ) {
    final fromUserId = request['fromUserId'];

    return FutureBuilder<Map<String, String>>(
      future: _userDataService.getUserData(fromUserId),

      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return DefaultLoadingContainer(
            width: double.infinity,
            height: 90,
            borderRadius: BorderRadius.circular(25),
          );
        }

        final userData = userSnapshot.data!;
        final name = userData['name'] ?? 'Unknown User';
        final username = userData['username'] ?? 'unknown';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FriendAcceptRejectPage(
                  userId: fromUserId,
                  requestId: request.id,
                ),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  FutureBuilder<String?>(
                    future: FirebaseStorageService.getProfileImageUrl(
                      fromUserId,
                    ),
                    builder: (context, imageSnapshot) {
                      return UserAvatar(
                        imageUrl: imageSnapshot.data,
                        radius: screenWidth * 0.07,
                      );
                    },
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.045,
                            fontFamily: 'Irina',
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          '@$username',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontFamily: 'Irina',
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildActionButton(
                    text: 'Accept',
                    color: Color.fromARGB(255, 86, 201, 46),
                    onTap: () => _acceptRequest(request, fromUserId),
                  ),
                  SizedBox(width: 8),
                  _buildActionButton(
                    text: 'Reject',
                    color: Color.fromARGB(255, 253, 65, 64),
                    onTap: () => _rejectRequest(request),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSentRequestItem(
    QueryDocumentSnapshot request,
    double screenWidth,
    UserDataService profileService,
  ) {
    final toUserId = request['toUserId'];

    return FutureBuilder<Map<String, String>>(
      future: profileService.getUserData(toUserId),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) {
          return DefaultLoadingContainer(
            width: double.infinity,
            height: 90,
            borderRadius: BorderRadius.circular(25),
          );
        }

        final userData = userSnapshot.data!;
        final name = userData['name'] ?? 'Unknown User';
        final username = userData['username'] ?? 'unknown';

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                FutureBuilder<String?>(
                  future: FirebaseStorageService.getProfileImageUrl(toUserId),
                  builder: (context, imageSnapshot) {
                    return UserAvatar(
                      imageUrl: imageSnapshot.data,
                      radius: screenWidth * 0.07,
                    );
                  },
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth * 0.045,
                          fontFamily: 'Irina',
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontFamily: 'Irina',
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildActionButton(
                  text: 'Cancel',
                  color: Color.fromARGB(255, 253, 65, 64),
                  onTap: () => _cancelRequest(
                    profileService.currentLoggedInUid,
                    toUserId,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Irina',
          ),
        ),
      ),
    );
  }

  Future<void> _acceptRequest(
    QueryDocumentSnapshot request,
    String fromUserId,
  ) async {
    try {
      await _userFriendsService.acceptFriendRequest(
        request.id,
        fromUserId,
        _userDataService.currentLoggedInUid,
      );
      await _userFriendsService.refreshFriends();

      _hasAcceptedRequest = true;

      if (mounted && context.mounted) {
        PopupNotificationService.showSuccess(
          context: context,
          message: 'Friend request accepted!',
          position: NotificationPosition.bottom,
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: 'Failed to accept request',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  Future<void> _rejectRequest(QueryDocumentSnapshot request) async {
    try {
      await _userFriendsService.rejectFriendRequest(request.id);

      if (mounted && context.mounted) {
        PopupNotificationService.showInfo(
          context: context,
          message: 'Friend request rejected',
          position: NotificationPosition.bottom,
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: 'Failed to reject request',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  Future<void> _cancelRequest(String fromUserId, String toUserId) async {
    try {
      await _userFriendsService.cancelFriendRequest(fromUserId, toUserId);

      _hasCancelledRequest = true;

      if (mounted && context.mounted) {
        PopupNotificationService.showInfo(
          context: context,
          message: 'Friend request cancelled',
          position: NotificationPosition.bottom,
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: 'Failed to cancel request',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 35,
          decoration: BoxDecoration(
            color: isSelected ? Color.fromARGB(255, 86, 201, 46) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color.fromARGB(255, 86, 201, 46),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
                fontFamily: 'Irina',
                color: isSelected
                    ? Colors.white
                    : Color.fromARGB(255, 86, 201, 46),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _hasAcceptedRequest || _hasCancelledRequest);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        body: Column(
          children: [
            Container(
              width: screenWidth,
              height: screenHeight * 0.16,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 50,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Friend requests',
                        style: TextStyle(
                          fontSize: screenWidth * 0.09,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Irina',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        _buildToggleButton(
                          text: 'Received',
                          isSelected: _showReceived,
                          onTap: () => setState(() => _showReceived = true),
                          screenWidth: screenWidth,
                        ),
                        SizedBox(width: 12),
                        _buildToggleButton(
                          text: 'Sent',
                          isSelected: !_showReceived,
                          onTap: () => setState(() => _showReceived = false),
                          screenWidth: screenWidth,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 54,
                    left: 8,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(
                        context,
                        _hasAcceptedRequest || _hasCancelledRequest,
                      ),
                      child: Image.asset(
                        'assets/images/icons/prof_page/go_back.png',
                        width: screenWidth * 0.11,
                        height: screenWidth * 0.11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _showReceived
                  ? _buildReceivedRequestsWidget(screenWidth)
                  : _buildSentRequestsWidget(screenWidth),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:later/services/auth/friend_request.dart';
import 'package:later/services/auth/user_services.dart';
import 'package:later/views/widgets/overlay_notification.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';
import 'package:later/views/widgets/friends_logic_pages/friend_accept_reject_page.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  final FriendRequestService _requestService = FriendRequestService();
  static final Map<String, String?> _imageUrlCache = {};

  // Toggle state - true for Received, false for Sent
  bool _showReceived = true;

  OverlayEntry? _notificationOverlay;
  Timer? _notificationTimer;

  @override
  void dispose() {
    OverlayNotification.hide();
    _hideCurrentNotification();
    super.dispose();
  }

  Future<String?> _getImageUrl(String userId) async {
    if (_imageUrlCache.containsKey(userId)) {
      return _imageUrlCache[userId];
    }

    final optimizedPath = 'userdata/$userId/assets/images/profile_image_small';
    final originalPath = 'userdata/$userId/assets/images/profile_image';

    try {
      final ref = FirebaseStorage.instance.ref().child(optimizedPath);
      final url = await ref.getDownloadURL();
      _imageUrlCache[userId] = url;
      return url;
    } catch (e) {
      try {
        final ref = FirebaseStorage.instance.ref().child(originalPath);
        final url = await ref.getDownloadURL();
        _imageUrlCache[userId] = url;
        return url;
      } catch (e) {
        _imageUrlCache[userId] = null;
        return null;
      }
    }
  }

  void _showNotification(String message, Color color) {
    if (mounted && context.mounted) {
      // Hide any existing overlays
      _hideCurrentNotification();

      // Create overlay entry with entry animation
      final overlay = Overlay.of(context);

      _notificationOverlay = OverlayEntry(
        builder: (context) => _AnimatedNotification(
          message: message,
          color: color,
          onDismiss: _hideCurrentNotification,
          isEntry: true,
        ),
      );

      overlay.insert(_notificationOverlay!);

      // Auto dismiss after 2 seconds with exit animation
      _notificationTimer?.cancel();
      _notificationTimer = Timer(Duration(seconds: 2), () {
        _hideWithAnimation(message, color);
      });
    }
  }

  void _hideWithAnimation(String message, Color color) {
    if (_notificationOverlay == null || !mounted) return;

    try {
      // Remove current overlay
      _notificationOverlay?.remove();

      // Create exit animation overlay
      final overlay = Overlay.of(context);

      _notificationOverlay = OverlayEntry(
        builder: (context) => _AnimatedNotification(
          message: message,
          color: color,
          onDismiss: _hideCurrentNotification,
          isEntry: false, // Exit animation
        ),
      );

      overlay.insert(_notificationOverlay!);
    } catch (e) {
      print('Error in exit animation: $e');
      _hideCurrentNotification();
    }
  }

  void _hideCurrentNotification() {
    _notificationTimer?.cancel();
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }

  Widget _buildReceivedRequestsWidget(
    UserService userService,
    double screenWidth,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: _requestService.getPendingRequests(userService.uid!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
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
                  'Error loading friend requests',
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

        // Show loading indicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading friend requests...',
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

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
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
                  'No friend requests',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Irina',
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'When someone sends you a friend request,\nit will appear here',
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

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final fromUserId = request['fromUserId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(fromUserId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!userSnapshot.data!.exists) {
                  return SizedBox.shrink();
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData == null) {
                  return SizedBox.shrink();
                }

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
                            future: _getImageUrl(fromUserId),
                            builder: (context, imageSnapshot) {
                              ImageProvider avatar;
                              if (imageSnapshot.hasData &&
                                  imageSnapshot.data != null &&
                                  imageSnapshot.data!.isNotEmpty) {
                                avatar = NetworkImage(imageSnapshot.data!);
                              } else {
                                avatar = AssetImage(
                                  'assets/images/icons/navbar/icon-profile.png',
                                );
                              }
                              return CircleAvatar(
                                radius: screenWidth * 0.07,
                                backgroundImage: avatar,
                                backgroundColor: Colors.grey[200],
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
                          GestureDetector(
                            onTap: () async {
                              try {
                                await _requestService.acceptFriendRequest(
                                  request.id,
                                  fromUserId,
                                  userService.uid!,
                                );
                                await userService.refreshFriends();
                                _showNotification(
                                  'Friend request accepted!',
                                  Colors.green,
                                );
                              } catch (e) {
                                _showNotification(
                                  'Failed to accept request',
                                  Color.fromARGB(255, 253, 65, 64),
                                );
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 86, 201, 46),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Accept',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Irina',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          GestureDetector(
                            onTap: () async {
                              try {
                                await _requestService.rejectFriendRequest(
                                  request.id,
                                );
                                _showNotification(
                                  'Friend request rejected',
                                  Colors.blue,
                                );
                              } catch (e) {
                                _showNotification(
                                  'Failed to reject request',
                                  Color.fromARGB(255, 253, 65, 64),
                                );
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 253, 65, 64),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Reject',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Irina',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSentRequestsWidget(UserService userService, double screenWidth) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('friend_requests')
          .where('fromUserId', isEqualTo: userService.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
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
                  'Error loading sent requests',
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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading sent requests...',
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

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data!.docs;

        if (requests.isEmpty) {
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
                  'No sent requests',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Irina',
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Friend requests you send\nwill appear here',
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

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final toUserId = request['toUserId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(toUserId)
                  .get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!userSnapshot.data!.exists) {
                  return SizedBox.shrink();
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData == null) {
                  return SizedBox.shrink();
                }

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
                          future: _getImageUrl(toUserId),
                          builder: (context, imageSnapshot) {
                            ImageProvider avatar;
                            if (imageSnapshot.hasData &&
                                imageSnapshot.data != null &&
                                imageSnapshot.data!.isNotEmpty) {
                              avatar = NetworkImage(imageSnapshot.data!);
                            } else {
                              avatar = AssetImage(
                                'assets/images/icons/navbar/icon-profile.png',
                              );
                            }
                            return CircleAvatar(
                              radius: screenWidth * 0.07,
                              backgroundImage: avatar,
                              backgroundColor: Colors.grey[200],
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
                        GestureDetector(
                          onTap: () async {
                            try {
                              await _requestService.cancelFriendRequest(
                                userService.uid!,
                                toUserId,
                              );
                              _showNotification(
                                'Friend request cancelled',
                                Colors.blue,
                              );
                            } catch (e) {
                              _showNotification(
                                'Failed to cancel request',
                                Color.fromARGB(255, 253, 65, 64),
                              );
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 253, 65, 64),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Irina',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
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
                      // Received button (now on the left)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showReceived = true;
                            });
                          },
                          child: Container(
                            height: 35,
                            decoration: BoxDecoration(
                              color: _showReceived
                                  ? Color.fromARGB(255, 86, 201, 46)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color.fromARGB(255, 86, 201, 46),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Received',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Irina',
                                  color: _showReceived
                                      ? Colors.white
                                      : Color.fromARGB(255, 86, 201, 46),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Sent button (now on the right)
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _showReceived = false;
                            });
                          },
                          child: Container(
                            height: 35,
                            decoration: BoxDecoration(
                              color: _showReceived
                                  ? Colors.white
                                  : Color.fromARGB(255, 86, 201, 46),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color.fromARGB(255, 86, 201, 46),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Sent',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Irina',
                                  color: _showReceived
                                      ? Color.fromARGB(255, 86, 201, 46)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 54,
                  left: 8,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                ? _buildReceivedRequestsWidget(userService, screenWidth)
                : _buildSentRequestsWidget(userService, screenWidth),
          ),
        ],
      ),
    );
  }
}

// Animated notification widget remains the same
class _AnimatedNotification extends StatefulWidget {
  final String message;
  final Color color;
  final VoidCallback onDismiss;
  final bool isEntry;

  const _AnimatedNotification({
    required this.message,
    required this.color,
    required this.onDismiss,
    required this.isEntry,
  });

  @override
  State<_AnimatedNotification> createState() => _AnimatedNotificationState();
}

class _AnimatedNotificationState extends State<_AnimatedNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    if (widget.isEntry) {
      // Entry animations
      _slideAnimation = Tween<Offset>(
        begin: Offset(0, 1), // Start from bottom
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

      _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

      _controller.forward();
    } else {
      // Exit animations
      _slideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(0, 1), // Exit to bottom
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

      _fadeAnimation = Tween<double>(
        begin: 1.0,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

      _controller.forward().then((_) {
        widget.onDismiss();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.color == Colors.green
                        ? Icons.check_circle
                        : widget.color == Colors.blue
                        ? Icons.info
                        : Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontFamily: 'Irina',
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

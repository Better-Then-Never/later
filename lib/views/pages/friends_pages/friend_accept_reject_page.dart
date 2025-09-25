import 'package:flutter/material.dart';
import 'package:later/services/user_data_service.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/firebase_storage_service.dart';
import 'package:later/services/popup_notification_service.dart';
import 'dart:async';

class FriendAcceptRejectPage extends StatefulWidget {
  final String userId;
  final String requestId;

  const FriendAcceptRejectPage({
    super.key,
    required this.userId,
    required this.requestId,
  });

  @override
  State<FriendAcceptRejectPage> createState() => _FriendAcceptRejectPageState();
}

class _FriendAcceptRejectPageState extends State<FriendAcceptRejectPage> {
  bool _isAccepting = false;
  bool _isRejecting = false;
  final UserFriendsService _requestService = UserFriendsService();

  late final Future<String?> _profileImageFuture;
  late final Future<String?> _backgroundImageFuture;
  late final Future<Map<String, String>> _userInfoFuture;

  @override
  void initState() {
    super.initState();
    _initializeFutures();
  }

  void _initializeFutures() {
    _profileImageFuture = FirebaseStorageService.getOriginalProfileImageUrl(
      widget.userId,
    );
    _backgroundImageFuture = FirebaseStorageService.getBackgroundImageUrl(
      widget.userId,
    );
  }

  @override
  void dispose() {
    PopupNotificationService.hide();
    super.dispose();
  }

  Future<void> _acceptFriendRequest() async {
    setState(() {
      _isAccepting = true;
    });

    try {
      final userService = Provider.of<UserDataService>(context, listen: false);
      final userFriendsService = Provider.of<UserFriendsService>(
        context,
        listen: false,
      );
      await _requestService.acceptFriendRequest(
        widget.requestId,
        widget.userId,
        userService.currentLoggedInUid,
      );

      await userFriendsService.refreshFriends();

      if (mounted && context.mounted) {
        PopupNotificationService.showSuccess(
          context: context,
          message: 'Friend request accepted!',
          position: NotificationPosition.center,
        );

        Timer(const Duration(seconds: 2), () {
          if (mounted && context.mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted && context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: 'Failed to accept request',
          position: NotificationPosition.center,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  Future<void> _rejectFriendRequest() async {
    setState(() {
      _isRejecting = true;
    });

    try {
      await _requestService.rejectFriendRequest(widget.requestId);

      if (mounted && context.mounted) {
        PopupNotificationService.showInfo(
          context: context,
          message: 'Friend request rejected',
          position: NotificationPosition.center,
        );

        Timer(const Duration(seconds: 2), () {
          if (mounted && context.mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted && context.mounted) {
        PopupNotificationService.showError(
          context: context,
          message: 'Failed to reject request',
          position: NotificationPosition.center,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRejecting = false;
        });
      }
    }
  }

  Widget _buildBackgroundImage(double screenWidth, double bgHeight) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(25),
        bottomRight: Radius.circular(25),
      ),
      child: Container(
        width: screenWidth,
        height: bgHeight,
        color: Colors.grey[300],
        child: FutureBuilder<String?>(
          future: _backgroundImageFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.grey[600],
                    strokeWidth: 3,
                  ),
                ),
              );
            } else if (snapshot.hasData && snapshot.data != null) {
              return Image.network(
                snapshot.data!,
                width: screenWidth,
                height: bgHeight,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.grey[600],
                        strokeWidth: 3,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey[500],
                    ),
                  );
                },
              );
            } else {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(double avatarRadius) {
    return Material(
      elevation: 8,
      shape: const CircleBorder(),
      child: FutureBuilder<String?>(
        future: _profileImageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: avatarRadius * 2,
              height: avatarRadius * 2,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.grey[600],
                  strokeWidth: 3,
                ),
              ),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            return CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.grey[300],
              child: ClipOval(
                child: Image.network(
                  snapshot.data!,
                  width: avatarRadius * 2,
                  height: avatarRadius * 2,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Container(
                      width: avatarRadius * 2,
                      height: avatarRadius * 2,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.grey[600],
                          strokeWidth: 3,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/icons/prof_page/no_photo.png',
                      width: avatarRadius * 2,
                      height: avatarRadius * 2,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            );
          } else {
            return CircleAvatar(
              radius: avatarRadius,
              backgroundImage: const AssetImage(
                'assets/images/icons/prof_page/no_photo.png',
              ),
              backgroundColor: Colors.grey[200],
            );
          }
        },
      ),
    );
  }

  Widget _buildUserInfo() {
    return FutureBuilder<Map<String, String>>(
      future: _userInfoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              Container(
                width: 120,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.grey[600],
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.grey[500],
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
            ],
          );
        } else if (snapshot.hasData) {
          final name = snapshot.data!['name'] ?? 'Unknown User';
          final username = snapshot.data!['username'] ?? 'unknown';
          return Column(
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '@$username',
                style: const TextStyle(
                  fontSize: 22,
                  color: Color.fromARGB(255, 94, 94, 94),
                  fontFamily: 'Irina',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        } else {
          return const Column(
            children: [
              Text(
                'Unknown User',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                '@unknown',
                style: TextStyle(
                  fontSize: 22,
                  color: Color.fromARGB(255, 94, 94, 94),
                  fontFamily: 'Irina',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildActionButton({
    required String text,
    required Color backgroundColor,
    required bool isLoading,
    required VoidCallback? onPressed,
    required int flex,
    required double screenWidth,
    required double screenHeight,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              spreadRadius: 1,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          borderRadius: BorderRadius.circular(25),
        ),
        child: SizedBox(
          height: screenHeight * 0.06,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            onPressed: onPressed,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      fontSize: screenWidth * 0.065,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Irina',
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(double screenWidth, double screenHeight) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: screenHeight * 0.1,
      child: Row(
        children: [
          _buildActionButton(
            text: 'Accept',
            backgroundColor: const Color.fromARGB(255, 86, 201, 46),
            isLoading: _isAccepting,
            onPressed: _isAccepting || _isRejecting
                ? null
                : _acceptFriendRequest,
            flex: 3,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
          ),
          const SizedBox(width: 8),
          _buildActionButton(
            text: 'Reject',
            backgroundColor: const Color.fromARGB(255, 253, 65, 64),
            isLoading: _isRejecting,
            onPressed: _isAccepting || _isRejecting
                ? null
                : _rejectFriendRequest,
            flex: 2,
            screenWidth: screenWidth,
            screenHeight: screenHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildShadowOverlay(double screenWidth) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        width: screenWidth,
        height: 1,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 0, 0, 0),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(120),
              spreadRadius: 60,
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 32,
      left: 16,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Image.asset(
          'assets/images/icons/prof_page/go_back_circle.png',
          width: 44,
          height: 44,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double bgHeight = screenHeight * 0.32;
    final double avatarRadius = 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: screenHeight * 0.45),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _buildBackgroundImage(screenWidth, bgHeight),
                    _buildShadowOverlay(screenWidth),
                    _buildBackButton(),
                    Positioned(
                      top: bgHeight - avatarRadius,
                      left: (screenWidth - avatarRadius * 2) / 2,
                      child: _buildProfileAvatar(avatarRadius),
                    ),
                  ],
                ),
                const SizedBox(height: 110),
                _buildUserInfo(),
              ],
            ),
          ),
          _buildActionButtons(screenWidth, screenHeight),
        ],
      ),
    );
  }
}

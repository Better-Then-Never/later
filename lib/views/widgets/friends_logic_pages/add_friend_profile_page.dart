import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:later/services/auth/user_services.dart';
import 'package:later/services/auth/friend_request.dart';
import 'package:later/views/widgets/overlay_notification.dart';

class AddFriendProfilePage extends StatefulWidget {
  final String userId;
  final VoidCallback? onStateChanged;

  const AddFriendProfilePage({
    super.key,
    required this.userId,
    this.onStateChanged,
  });

  @override
  State<AddFriendProfilePage> createState() => _AddFriendProfilePageState();
}

class _AddFriendProfilePageState extends State<AddFriendProfilePage> {
  bool _isLoading = false;
  bool _isCancelling = false;
  String _buttonState = 'add'; // 'add', 'pending', 'friends'
  final FriendRequestService _requestService = FriendRequestService();

  static final Map<String, String?> _profileImageCache = {};
  static final Map<String, String?> _backgroundImageCache = {};
  static final Map<String, Map<String, String>> _nameUsernameCache = {};

  @override
  void initState() {
    super.initState();
    _checkRelationshipStatus();
  }

  @override
  void dispose() {
    OverlayNotification.hide();
    super.dispose();
  }

  Future<void> _checkRelationshipStatus() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final currentUserUid = userService.uid;

      if (currentUserUid != null) {
        // Check if already friends
        final areFriends = await _requestService.areFriends(
          currentUserUid,
          widget.userId,
        );
        if (areFriends) {
          setState(() {
            _buttonState = 'friends';
          });
          return;
        }

        // Check if there's a pending request
        final requestExists = await _requestService.requestExists(
          currentUserUid,
          widget.userId,
        );
        if (requestExists) {
          setState(() {
            _buttonState = 'pending';
          });
          return;
        }

        // Default to add
        setState(() {
          _buttonState = 'add';
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<String?> _getProfileImageUrl() async {
    if (_profileImageCache.containsKey(widget.userId)) {
      return _profileImageCache[widget.userId];
    }
    final originalPath =
        'userdata/${widget.userId}/assets/images/profile_image';
    try {
      final ref = FirebaseStorage.instance.ref().child(originalPath);
      final url = await ref.getDownloadURL();
      _profileImageCache[widget.userId] = url;
      return url;
    } catch (e) {
      _profileImageCache[widget.userId] = null;
      return null;
    }
  }

  Future<String?> _getBackgroundImageUrl() async {
    if (_backgroundImageCache.containsKey(widget.userId)) {
      return _backgroundImageCache[widget.userId];
    }
    final bgPath = 'userdata/${widget.userId}/assets/images/background_image';
    try {
      final ref = FirebaseStorage.instance.ref().child(bgPath);
      final url = await ref.getDownloadURL().timeout(Duration(seconds: 10));
      _backgroundImageCache[widget.userId] = url;
      return url;
    } catch (e) {
      _backgroundImageCache[widget.userId] = null;
      return null;
    }
  }

  Future<Map<String, String>> _getNameAndUsername() async {
    if (_nameUsernameCache.containsKey(widget.userId)) {
      return _nameUsernameCache[widget.userId]!;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    final data = doc.data();
    final result = {
      'name': (data?['name'] ?? '').toString(),
      'username': (data?['username'] ?? '').toString(),
    };
    _nameUsernameCache[widget.userId] = result;
    return result;
  }

  Future<void> _handleButtonPress() async {
    if (_buttonState == 'friends') {
      // Show info that they're already friends
      if (mounted) {
        OverlayNotification.showInfo(
          context: context,
          message: 'You are already friends!',
          position: NotificationPosition.center,
        );
      }
      return;
    }

    if (_buttonState == 'pending') {
      // Show info that request is pending
      if (mounted) {
        OverlayNotification.showInfo(
          context: context,
          message: 'Friend request is pending',
          position: NotificationPosition.center,
        );
      }
      return;
    }

    // Send friend request
    setState(() {
      _isLoading = true;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);

      // Check if request already exists (double-check)
      final requestExists = await _requestService.requestExists(
        userService.uid!,
        widget.userId,
      );

      if (requestExists) {
        if (mounted) {
          setState(() {
            _buttonState = 'pending';
          });
          OverlayNotification.showInfo(
            context: context,
            message: 'Friend request already exists',
            position: NotificationPosition.center,
          );
        }
        // Notify parent of state change
        widget.onStateChanged?.call();
        return;
      }

      await _requestService.sendFriendRequest(userService.uid!, widget.userId);

      if (mounted) {
        setState(() {
          _buttonState = 'pending';
        });

        // Notify parent of state change
        widget.onStateChanged?.call();

        OverlayNotification.showSuccess(
          context: context,
          message: 'Friend request sent!',
          position: NotificationPosition.center,
        );
      }
    } catch (e) {
      if (mounted) {
        OverlayNotification.showError(
          context: context,
          message: 'Failed to send friend request',
          position: NotificationPosition.center,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelFriendRequest() async {
    setState(() {
      _isCancelling = true;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final requestId = '${userService.uid!}_${widget.userId}';

      await _requestService.rejectFriendRequest(requestId);

      if (mounted) {
        setState(() {
          _buttonState = 'add';
        });

        // Notify parent of state change
        widget.onStateChanged?.call();

        OverlayNotification.showInfo(
          context: context,
          message: 'Friend request cancelled',
          position: NotificationPosition.center,
        );
      }
    } catch (e) {
      if (mounted) {
        OverlayNotification.showError(
          context: context,
          message: 'Failed to cancel request',
          position: NotificationPosition.center,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  String _getButtonText() {
    switch (_buttonState) {
      case 'pending':
        return 'Pending';
      case 'friends':
        return 'Friends';
      default:
        return 'Add';
    }
  }

  Color _getButtonColor() {
    switch (_buttonState) {
      case 'pending':
        return Color.fromARGB(255, 253, 219, 7);
      case 'friends':
        return Colors.grey[400]!;
      default:
        return const Color.fromARGB(255, 86, 201, 46);
    }
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
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      ),
                      child: Container(
                        width: screenWidth,
                        height: bgHeight,
                        color: Colors.grey[300],
                        child: FutureBuilder<String?>(
                          future: _getBackgroundImageUrl(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
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
                            } else if (snapshot.hasData &&
                                snapshot.data != null) {
                              return Image.network(
                                snapshot.data!,
                                width: screenWidth,
                                height: bgHeight,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
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
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
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
                    ),
                    Positioned(
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
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
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
                    ),
                    Positioned(
                      top: 33,
                      right: 16,
                      child: Image.asset(
                        'assets/images/icons/prof_page/share_button.png',
                        width: 44,
                        height: 44,
                      ),
                    ),
                    Positioned(
                      top: bgHeight - avatarRadius,
                      left: (screenWidth - avatarRadius * 2) / 2,
                      child: Material(
                        elevation: 8,
                        shape: const CircleBorder(),
                        child: FutureBuilder<String?>(
                          future: _getProfileImageUrl(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
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
                            } else if (snapshot.hasData &&
                                snapshot.data != null) {
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
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/images/icons/navbar/icon-profile.png',
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
                                backgroundImage: AssetImage(
                                  'assets/images/icons/navbar/icon-profile.png',
                                ),
                                backgroundColor: Colors.grey[200],
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 110),
                FutureBuilder<Map<String, String>>(
                  future: _getNameAndUsername(),
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
                          SizedBox(height: 8),
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
                      final name = snapshot.data!['name'] ?? '';
                      final username = snapshot.data!['username'] ?? '';
                      return Column(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '@$username',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Color.fromARGB(255, 94, 94, 94),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          Text(
                            'Unknown User',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '@unknown',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Color.fromARGB(255, 94, 94, 94),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          // Main button (Add/Pending/Friends)
          Positioned(
            left: screenWidth * 0.15,
            right: screenWidth * 0.15,
            bottom: _buttonState == 'pending'
                ? screenHeight * 0.16
                : screenHeight * 0.1,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    spreadRadius: 1,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
                borderRadius: BorderRadius.circular(25),
              ),
              child: SizedBox(
                width: screenWidth * 0.73,
                height: screenHeight * 0.06,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _handleButtonPress,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _getButtonText(),
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
          ),
          // Cancel button (only visible when pending)
          if (_buttonState == 'pending')
            Positioned(
              left: screenWidth * 0.25,
              right: screenWidth * 0.25,
              bottom: screenHeight * 0.1,
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      spreadRadius: 1,
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: SizedBox(
                  width: screenWidth * 0.5,
                  height: screenHeight * 0.05,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isCancelling ? null : _cancelFriendRequest,
                    child: _isCancelling
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Cancel Request',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Irina',
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

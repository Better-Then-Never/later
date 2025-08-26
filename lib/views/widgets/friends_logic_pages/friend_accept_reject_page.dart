import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:later/services/auth/user_services.dart';
import 'package:later/services/auth/friend_request.dart';
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
  final FriendRequestService _requestService = FriendRequestService();

  static final Map<String, String?> _profileImageCache = {};
  static final Map<String, String?> _backgroundImageCache = {};
  static final Map<String, Map<String, String>> _nameUsernameCache = {};

  // Add these variables for custom notifications
  OverlayEntry? _notificationOverlay;
  Timer? _notificationTimer;

  @override
  void dispose() {
    _hideCurrentNotification();
    super.dispose();
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

  Future<void> _acceptFriendRequest() async {
    setState(() {
      _isAccepting = true;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);

      await _requestService.acceptFriendRequest(
        widget.requestId,
        widget.userId,
        userService.uid!,
      );

      await userService.refreshFriends();

      _showNotification('Friend request accepted!', Colors.green);

      // Auto close after success
      Timer(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      _showNotification(
        'Failed to accept request',
        Color.fromARGB(255, 253, 65, 64),
      );
    } finally {
      setState(() {
        _isAccepting = false;
      });
    }
  }

  Future<void> _rejectFriendRequest() async {
    setState(() {
      _isRejecting = true;
    });

    try {
      await _requestService.rejectFriendRequest(widget.requestId);

      _showNotification('Friend request rejected', Colors.blue);

      // Auto close after success
      Timer(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      _showNotification(
        'Failed to reject request',
        Color.fromARGB(255, 253, 65, 64),
      );
    } finally {
      setState(() {
        _isRejecting = false;
      });
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
          Positioned(
            left: 16,
            right: 16,
            bottom: screenHeight * 0.1,
            child: Row(
              children: [
                // Accept button (wider)
                Expanded(
                  flex: 3, // Makes accept button wider
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
                      height: screenHeight * 0.06,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 86, 201, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isAccepting || _isRejecting
                            ? null
                            : _acceptFriendRequest,
                        child: _isAccepting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Accept',
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
                SizedBox(width: 8), // 8px spacing between buttons
                // Reject button (narrower)
                Expanded(
                  flex: 2, // Makes reject button narrower
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
                      height: screenHeight * 0.06,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 253, 65, 64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _isAccepting || _isRejecting
                            ? null
                            : _rejectFriendRequest,
                        child: _isRejecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Reject',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Animated notification widget (same as in friend_requests_page.dart)
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

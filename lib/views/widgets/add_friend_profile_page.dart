import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:later/services/auth/user_services.dart';
import 'package:later/views/widgets/overlay_notification.dart'; // Add this import

class AddFriendProfilePage extends StatefulWidget {
  final String userId;

  const AddFriendProfilePage({super.key, required this.userId});

  @override
  State<AddFriendProfilePage> createState() => _AddFriendProfilePageState();
}

class _AddFriendProfilePageState extends State<AddFriendProfilePage> {
  bool _isAdding = false;
  bool _isFriendAdded = false; // Track if friend is already added

  static final Map<String, String?> _profileImageCache = {};
  static final Map<String, String?> _backgroundImageCache = {};
  static final Map<String, Map<String, String>> _nameUsernameCache = {};

  @override
  void initState() {
    super.initState();
    _checkIfFriendExists();
  }

  @override
  void dispose() {
    OverlayNotification.hide(); // Clean up any active notifications
    super.dispose();
  }

  Future<void> _checkIfFriendExists() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final currentUserUid = userService.uid;
      
      if (currentUserUid != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserUid)
            .get();
        
        final userData = doc.data();
        final friends = List<String>.from(userData?['friends'] ?? []);
        
        setState(() {
          _isFriendAdded = friends.contains(widget.userId);
        });
      }
    } catch (e) {
      // Handle error silently or show error notification if needed
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
      final url = await ref.getDownloadURL();
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
      'username': (data?['username'] ?? '').toString()
    };
    _nameUsernameCache[widget.userId] = result;
    return result;
  }

  Future<void> _addFriend() async {
    // If friend is already added, show info notification
    if (_isFriendAdded) {
      OverlayNotification.showInfo(
        context: context,
        message: 'This user is already your friend!',
        position: NotificationPosition.center,
      );
      return;
    }

    setState(() {
      _isAdding = true;
    });

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.addFriend(widget.userId);
      
      setState(() {
        _isFriendAdded = true;
      });

      OverlayNotification.showSuccess(
        context: context,
        message: 'Friend added!',
        position: NotificationPosition.center,
      );
    } catch (e) {
      OverlayNotification.showError(
        context: context,
        message: 'Failed to add friend',
        position: NotificationPosition.center,
      );
    } finally {
      setState(() {
        _isAdding = false;
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
                              return Container(color: Colors.grey[300]);
                            } else if (snapshot.hasData && snapshot.data != null) {
                              return Image.network(
                                snapshot.data!,
                                width: screenWidth,
                                height: bgHeight,
                                fit: BoxFit.cover,
                              );
                            } else {
                              return Container(color: Colors.grey[300]);
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
                            if (snapshot.hasData && snapshot.data != null) {
                              return CircleAvatar(
                                radius: avatarRadius,
                                backgroundImage: NetworkImage(snapshot.data!),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              width: 120,
                              height: 24,
                              color: Colors.grey[300],
                            ),
                          ),
                          SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Container(
                              width: 80,
                              height: 18,
                              color: Colors.grey[200],
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
                      return SizedBox.shrink();
                    }
                  },
                ),
              ],
            ),
          ),
          Positioned(
            left: screenWidth * 0.15,
            right: screenWidth * 0.15,
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
                width: screenWidth * 0.73,
                height: screenHeight * 0.06,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFriendAdded 
                        ? Colors.grey[400] // Different color when already added
                        : Color.fromARGB(255, 86, 201, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isAdding ? null : _addFriend,
                  child: _isAdding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isFriendAdded ? "Added" : "Add",
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
    );
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:later/views/widgets/friends_logic_pages/friend_options_modal.dart';

class YourFriendProfilePage extends StatelessWidget {
  final String friendUid;

  const YourFriendProfilePage({super.key, required this.friendUid});

  static final Map<String, _CachedImage> _profileImageCacheNew = {};
  static final Map<String, _CachedImage> _backgroundImageCacheNew = {};
  static final Map<String, _CachedUserData> _nameUsernameCacheNew = {};

  static const Duration _cacheExpiration = Duration(hours: 1);

  Future<String?> _getProfileImageUrl() async {
    final now = DateTime.now();

    if (_profileImageCacheNew.containsKey(friendUid)) {
      final cached = _profileImageCacheNew[friendUid]!;
      if (now.difference(cached.timestamp) < _cacheExpiration) {
        return cached.url;
      } else {
        _profileImageCacheNew.remove(friendUid);
      }
    }

    final originalPath = 'userdata/$friendUid/assets/images/profile_image';
    try {
      final ref = FirebaseStorage.instance.ref().child(originalPath);
      final url = await ref.getDownloadURL();

      _profileImageCacheNew[friendUid] = _CachedImage(url: url, timestamp: now);

      return url;
    } catch (e) {
      _profileImageCacheNew[friendUid] = _CachedImage(
        url: null,
        timestamp: now,
      );
      return null;
    }
  }

  Future<String?> _getBackgroundImageUrl() async {
    final now = DateTime.now();

    if (_backgroundImageCacheNew.containsKey(friendUid)) {
      final cached = _backgroundImageCacheNew[friendUid]!;
      if (now.difference(cached.timestamp) < _cacheExpiration) {
        return cached.url;
      } else {
        _backgroundImageCacheNew.remove(friendUid);
      }
    }

    final bgPath = 'userdata/$friendUid/assets/images/background_image';
    try {
      final ref = FirebaseStorage.instance.ref().child(bgPath);
      final url = await ref.getDownloadURL().timeout(Duration(seconds: 10));

      _backgroundImageCacheNew[friendUid] = _CachedImage(
        url: url,
        timestamp: now,
      );

      return url;
    } catch (e) {
      _backgroundImageCacheNew[friendUid] = _CachedImage(
        url: null,
        timestamp: now,
      );
      return null;
    }
  }

  Future<Map<String, String>> _getNameAndUsername() async {
    final now = DateTime.now();

    if (_nameUsernameCacheNew.containsKey(friendUid)) {
      final cached = _nameUsernameCacheNew[friendUid]!;
      if (now.difference(cached.timestamp) < _cacheExpiration) {
        return cached.data;
      } else {
        _nameUsernameCacheNew.remove(friendUid);
      }
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(friendUid)
          .get();
      final data = doc.data();
      final result = {
        'name': (data?['name'] ?? '').toString(),
        'username': (data?['username'] ?? '').toString(),
      };

      _nameUsernameCacheNew[friendUid] = _CachedUserData(
        data: result,
        timestamp: now,
      );

      return result;
    } catch (e) {
      final defaultResult = {'name': 'Unknown User', 'username': 'unknown'};

      _nameUsernameCacheNew[friendUid] = _CachedUserData(
        data: defaultResult,
        timestamp: now,
      );

      return defaultResult;
    }
  }

  static void clearUserCache(String uid) {
    _profileImageCacheNew.remove(uid);
    _backgroundImageCacheNew.remove(uid);
    _nameUsernameCacheNew.remove(uid);
  }

  static void clearExpiredCache() {
    final now = DateTime.now();

    _profileImageCacheNew.removeWhere(
      (key, value) => now.difference(value.timestamp) >= _cacheExpiration,
    );
    _backgroundImageCacheNew.removeWhere(
      (key, value) => now.difference(value.timestamp) >= _cacheExpiration,
    );
    _nameUsernameCacheNew.removeWhere(
      (key, value) => now.difference(value.timestamp) >= _cacheExpiration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    clearExpiredCache();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: screenWidth,
                  height: 230,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: FutureBuilder<String?>(
                    future: _getBackgroundImageUrl(),
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
                        return ClipRRect(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                          ),
                          child: Image.network(
                            snapshot.data!,
                            width: screenWidth,
                            height: 230,
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
                                    value:
                                        loadingProgress.expectedTotalBytes !=
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
                          ),
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
                Container(
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
                Positioned(
                  top: 35,
                  left: 12,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 0),
                    icon: Image.asset(
                      'assets/images/icons/prof_page/go_back_circle.png',
                      width: 41,
                      height: 41,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                // Right side icons - moved down a bit
                Positioned(
                  top: 35,
                  right: 12,
                  child: Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(minWidth: 0),
                        icon: Image.asset(
                          'assets/images/icons/prof_page/share_button.png',
                          width: 41,
                          height: 41,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          // TODO: Handle send capsule action
                        },
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(minWidth: 0),
                        icon: Image.asset(
                          'assets/images/icons/prof_page/open_menu.png',
                          width: 41,
                          height: 41,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          FriendOptionsModal.show(context, friendUid);
                        },
                      ),
                    ],
                  ),
                ),

                Positioned(
                  top: 99,
                  left: 16,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      FutureBuilder<String?>(
                        future: _getProfileImageUrl(),
                        builder: (context, snapshot) {
                          return Container(
                            width: 115,
                            height: 115,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(50),
                                  spreadRadius: 1,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child:
                                snapshot.connectionState ==
                                    ConnectionState.waiting
                                ? Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.grey[600],
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  )
                                : snapshot.hasData && snapshot.data != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: Image.network(
                                      snapshot.data!,
                                      width: 115,
                                      height: 115,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) {
                                          return child;
                                        }
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(
                                              25,
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
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          child: Image.asset(
                                            'assets/images/icons/prof_page/no_photo.png',
                                            width: 115,
                                            height: 115,
                                            fit: BoxFit.cover,
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(25),
                                    child: Image.asset(
                                      'assets/images/icons/prof_page/no_photo.png',
                                      width: 115,
                                      height: 115,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      FutureBuilder<Map<String, String>>(
                        future: _getNameAndUsername(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 120,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(200),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.grey[600],
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: 100,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(150),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        color: Colors.grey[600],
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: AutoSizeText(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      height: 1,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 12,
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: AutoSizeText(
                                    '@$username',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      height: 1,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 12,
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: AutoSizeText(
                                    "Unknown User",
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      height: 1,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 12,
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: AutoSizeText(
                                    "@unknown",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.normal,
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      height: 1,
                                    ),
                                    maxLines: 1,
                                    minFontSize: 12,
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(40),
                                spreadRadius: 1,
                                blurRadius: 9,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: () {
                              // TODO: Handle open chat action
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              splashFactory: NoSplash.splashFactory,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              overlayColor: Colors.transparent,
                            ),
                            icon: Image.asset(
                              'assets/images/icons/prof_page/send_message.png',
                              width: 24,
                              height: 24,
                            ),
                            label: Text(
                              'Open chat',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Irina',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(40),
                                spreadRadius: 1,
                                blurRadius: 9,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextButton.icon(
                            onPressed: () {
                              // TODO: Handle send capsule action
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              splashFactory: NoSplash.splashFactory,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              overlayColor: Colors.transparent,
                            ),
                            icon: Image.asset(
                              'assets/images/icons/prof_page/send_capsule.png',
                              width: 24,
                              height: 24,
                            ),
                            label: Text(
                              'Send capsule',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Irina',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Friend's capsules",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: screenWidth - 32,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          spreadRadius: 1,
                          blurRadius: 9,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Friend's capsules will appear here",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontFamily: 'Irina',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CachedImage {
  final String? url;
  final DateTime timestamp;

  _CachedImage({required this.url, required this.timestamp});
}

class _CachedUserData {
  final Map<String, String> data;
  final DateTime timestamp;

  _CachedUserData({required this.data, required this.timestamp});
}

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:later/services/auth/name_getting.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RandomFriendsRow extends StatefulWidget {
  final String currentUserUid;
  final void Function(List<String>)? onPinnedFriends;

  const RandomFriendsRow({
    super.key,
    required this.currentUserUid,
    this.onPinnedFriends,
  });

  @override
  State<RandomFriendsRow> createState() => _RandomFriendsRowState();
}

class _RandomFriendsRowState extends State<RandomFriendsRow> {
  static final Map<String, String?> _imageUrlCache = {};
  List<String> _pinnedFriendUids = [];
  Map<String, String?> _pinnedFriendImages = {};

  @override
  void initState() {
    super.initState();
    _loadPinnedFriends();
  }

  Future<void> _loadPinnedFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final uids = prefs.getStringList('pinned_friend_uids') ?? [];
    Map<String, String?> images = {};
    for (final uid in uids) {
      images[uid] = await _getImageUrl(uid);
    }
    setState(() {
      _pinnedFriendUids = uids;
      _pinnedFriendImages = images;
    });
  }

  Future<void> _setPinnedFriends(List<String> uids) async {
    final prefs = await SharedPreferences.getInstance();

    // Get current friends list from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserUid)
        .get();
    final data = userDoc.data() ?? {};
    final friendsList = List<String>.from(data['friends'] ?? []);

    // Only keep UIDs that are in friendsList
    final filteredUids = uids.where((uid) => friendsList.contains(uid)).toList();

    await prefs.setStringList('pinned_friend_uids', filteredUids);
    Map<String, String?> images = {};
    for (final uid in filteredUids) {
      images[uid] = await _getImageUrl(uid);
    }
    setState(() {
      _pinnedFriendUids = filteredUids;
      _pinnedFriendImages = images;
    });
    if (widget.onPinnedFriends != null) {
      widget.onPinnedFriends!(filteredUids);
    }
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

  Future<List<Map<String, String>>> _getFriendsData(
    List<String> friendsList, {
    int max = 3,
  }) async {
    final limitedList = List<String>.from(friendsList);
    limitedList.shuffle();
    final selectedUids = limitedList.take(max).toList();
    List<Map<String, String>> fetchedFriends = [];
    for (final uid in selectedUids) {
      final imageUrl = await _getImageUrl(uid);
      fetchedFriends.add({'uid': uid, 'imageUrl': imageUrl ?? ''});
    }
    return fetchedFriends;
  }

  Future<void> _showChoosePinnedFriendsModal(
    BuildContext context,
    List<String> friendsList,
  ) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (BuildContext context) {
        List<String> tempPinned = List<String>.from(_pinnedFriendUids);
        TextEditingController _searchController = TextEditingController();
        String _searchQuery = '';

        // Fetch latest friends data from Firestore
        return FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait(
            friendsList.map(
              (friendId) => FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendId)
                  .get(),
            ),
          ),
          builder: (context, friendsSnapshot) {
            if (friendsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!friendsSnapshot.hasData || friendsSnapshot.data!.isEmpty) {
              return const Center(child: Text('No friends found'));
            }
            final friendsDocs = friendsSnapshot.data!;
            // Build info map for search
            final friendInfoMap = <String, Map<String, String>>{};
            for (var doc in friendsDocs) {
              final friendData = doc.data() as Map<String, dynamic>? ?? {};
              final uid = doc.id;
              friendInfoMap[uid] = {
                'name': friendData['name'] ?? '',
                'username': friendData['username'] ?? '',
              };
            }

            // Keep the full list for filtering
            List<String> allFriends = friendsList;

            return StatefulBuilder(
              builder: (context, setModalState) {
                // Filter by search
                final filteredFriends = allFriends.where((uid) {
                  final info = friendInfoMap[uid];
                  if (info == null) return false;
                  final name = info['name']?.toLowerCase() ?? '';
                  final username = info['username']?.toLowerCase() ?? '';
                  return name.contains(_searchQuery) ||
                      username.contains(_searchQuery);
                }).toList();

                // Sort so checked (pinned) friends are always on top
                filteredFriends.sort((a, b) {
                  final aPinned = tempPinned.contains(a) ? 0 : 1;
                  final bPinned = tempPinned.contains(b) ? 0 : 1;
                  return aPinned.compareTo(bPinned);
                });

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Choose up to 3 pinned friends',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 86, 201, 46),
                          fontFamily: 'Irina',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'If you choose fewer than 3, random friends from your list will be shown',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color.fromARGB(255, 0, 0, 0),
                          fontFamily: 'Irina',
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // --- Search Bar ---
                      Container(
                        height: 45,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12.0,
                              ),
                              child: Image.asset(
                                'assets/images/icons/friends_page/look_for.png',
                                width: 28,
                                height: 28,
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: const InputDecoration(
                                  hintText: "Search...",
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                style: const TextStyle(
                                  fontFamily: 'Irina',
                                  fontSize: 22,
                                ),
                                onChanged: (val) {
                                  setModalState(() {
                                    _searchQuery = val.trim().toLowerCase();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      // --- Friends List ---
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredFriends.length,
                          itemBuilder: (context, index) {
                            final uid = filteredFriends[index];
                            final info = friendInfoMap[uid] ?? {};
                            final name = info['name'] ?? '';
                            final username = info['username'] ?? '';
                            final isPinned = tempPinned.contains(uid);
                            final imageUrl = _imageUrlCache[uid];
                            return ListTile(
                              leading: imageUrl != null && imageUrl.isNotEmpty
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(imageUrl),
                                      radius: 24,
                                    )
                                  : CircleAvatar(
                                      backgroundImage: const AssetImage(
                                        'assets/images/icons/prof_page/no_photo.png',
                                      ),
                                      radius: 24,
                                      backgroundColor: Color.fromARGB(
                                        255,
                                        244,
                                        188,
                                        0,
                                      ),
                                    ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Irina',
                                ),
                              ),
                              subtitle: Text(
                                '@$username',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Irina',
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: Checkbox(
                                value: isPinned,
                                activeColor: Color.fromARGB(255, 86, 201, 46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                onChanged: (val) {
                                  setModalState(() {
                                    if (val == true) {
                                      if (tempPinned.length < 3 &&
                                          !tempPinned.contains(uid)) {
                                        tempPinned.add(uid);
                                      }
                                    } else {
                                      tempPinned.remove(uid);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            86,
                            201,
                            46,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _setPinnedFriends(tempPinned);
                        },
                        child: const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showFriendOptionsModal(
    BuildContext context,
    String friendUid,
    List<String> friendsList,
  ) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 264,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 37,
                      width: 264,
                      child: Center(
                        child: NameGettingWidget(
                          uid: friendUid,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 86, 201, 46),
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 264,
                      height: 1,
                      color: Color.fromARGB(255, 86, 201, 46),
                    ),
                    SizedBox(
                      height: 37,
                      width: 264,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/yourFriendsProfilePage',
                            arguments: {'uid': friendUid},
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(0),
                              topRight: Radius.circular(0),
                            ),
                          ),
                        ),
                        child: const Center(child: Text('View profile page')),
                      ),
                    ),
                    Container(
                      width: 264,
                      height: 2,
                      color: Color.fromARGB(255, 211, 211, 211),
                    ),
                    SizedBox(
                      height: 37,
                      width: 264,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showChoosePinnedFriendsModal(context, friendsList);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.black,
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
                          ),
                        ),
                        child: const Center(
                          child: Text('Choose pinned friends'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final friendsList = List<String>.from(data['friends'] ?? []);
        if (friendsList.isEmpty) {
          return SizedBox(
            height: 70,
            child: const Align(
              alignment: Alignment.center,
              child: Text(
                'You have no friends yet',
                style: TextStyle(
                  fontSize: 20,
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        // Filter pinned friends to only those in friendsList
        final validPinnedUids =
            _pinnedFriendUids.where((uid) => friendsList.contains(uid)).toList();

        // If there are invalid pinned friends, update local state and SharedPreferences after build
        if (validPinnedUids.length != _pinnedFriendUids.length) {
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            _pinnedFriendUids = validPinnedUids;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setStringList('pinned_friend_uids', validPinnedUids);
            // Optionally, update images cache as well
            Map<String, String?> images = {};
            for (final uid in validPinnedUids) {
              images[uid] = _pinnedFriendImages[uid];
            }
            if (mounted) {
              setState(() {
                _pinnedFriendImages = images;
              });
            }
          });
        }

        List<Widget> friendWidgets = [];
        for (final uid in validPinnedUids) {
          ImageProvider avatar;
          final imageUrl = _pinnedFriendImages[uid];
          if (imageUrl != null && imageUrl.isNotEmpty) {
            avatar = NetworkImage(imageUrl);
          } else {
            avatar = const AssetImage(
              'assets/images/icons/prof_page/no_photo.png',
            );
          }
          friendWidgets.add(
            GestureDetector(
              onTap: () => _showFriendOptionsModal(context, uid, friendsList),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Color.fromARGB(255, 244, 188, 0),
                ),
                clipBehavior: Clip.hardEdge,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(image: avatar, fit: BoxFit.cover),
                  ),
                ),
              ),
            ),
          );
        }

        // Fill remaining slots with random friends
        final nonPinnedFriends = friendsList
            .where((uid) => !validPinnedUids.contains(uid))
            .toList();
        final slotsLeft = 3 - friendWidgets.length;
        if (slotsLeft > 0 && nonPinnedFriends.isNotEmpty) {
          return FutureBuilder<List<Map<String, String>>>(
            future: _getFriendsData(nonPinnedFriends, max: slotsLeft),
            builder: (context, friendSnapshot) {
              if (friendSnapshot.hasData) {
                final friendsData = friendSnapshot.data!;
                for (var friend in friendsData) {
                  ImageProvider avatar;
                  if (friend['imageUrl'] != null &&
                      friend['imageUrl']!.isNotEmpty) {
                    avatar = NetworkImage(friend['imageUrl']!);
                  } else {
                    avatar = const AssetImage(
                      'assets/images/icons/prof_page/no_photo.png',
                    );
                  }
                  friendWidgets.add(
                    GestureDetector(
                      onTap: () => _showFriendOptionsModal(
                        context,
                        friend['uid']!,
                        friendsList,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: Color.fromARGB(255, 244, 188, 0),
                        ),
                        clipBehavior: Clip.hardEdge,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: avatar,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              } else {
                friendWidgets.addAll(
                  List.generate(
                    slotsLeft,
                    (index) => SizedBox(
                      width: 110,
                      height: 110,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: friendWidgets.take(3).toList(),
              );
            },
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: friendWidgets.take(3).toList(),
        );
      },
    );
  }
}
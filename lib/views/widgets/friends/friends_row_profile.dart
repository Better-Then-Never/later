import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:later/services/firebase_storage_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/pages/friends_pages/your_friend_profile_page.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/views/widgets/user/user_round_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:later/views/widgets/_common/default_elements/default_search_bar.dart';
import 'package:provider/provider.dart';

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
  List<String> _pinnedFriendUids = [];
  Map<String, String?> _pinnedFriendImages = {};
  List<String> _friendsList = [];
  Map<String, Map<String, String>> _friendInfoMap = {};
  bool _isLoadingPinned = true;

  @override
  void initState() {
    super.initState();
    _loadPinnedFriends();
  }

  @override
  void dispose() {
    PopupNotificationService.hide();
    super.dispose();
  }

  Future<void> _loadPinnedFriends() async {
    final prefs = await SharedPreferences.getInstance();
    final uids = prefs.getStringList('pinned_friend_uids') ?? [];

    Map<String, String?> images = {};
    for (final uid in uids) {
      images[uid] = await FirebaseStorageService.getProfileImageUrl(uid);
    }

    if (mounted) {
      setState(() {
        _pinnedFriendUids = uids;
        _pinnedFriendImages = images;
        _isLoadingPinned = false;
      });
    }
  }

  Future<void> _setPinnedFriends(List<String> uids) async {
    final prefs = await SharedPreferences.getInstance();
    final filteredUids = uids
        .where((uid) => _friendsList.contains(uid))
        .toList();
    await prefs.setStringList('pinned_friend_uids', filteredUids);

    Map<String, String?> images = {};
    for (final uid in filteredUids) {
      if (_pinnedFriendImages.containsKey(uid)) {
        images[uid] = _pinnedFriendImages[uid];
      } else {
        images[uid] = await FirebaseStorageService.getProfileImageUrl(uid);
      }
    }

    if (mounted) {
      setState(() {
        _pinnedFriendUids = filteredUids;
        _pinnedFriendImages = images;
      });
    }

    widget.onPinnedFriends?.call(filteredUids);
  }

  Future<void> _updateFriendsData(List<String> friendsList) async {
    if (friendsList.isEmpty) {
      if (mounted) {
        setState(() {
          _friendsList = friendsList;
          _friendInfoMap = {};
        });
      }
      return;
    }

    final profileService = Provider.of<UserDataService>(context, listen: false);

    Map<String, Map<String, String>> infoMap = {};

    final results = await Future.wait(
      friendsList.map((uid) async {
        final data = await profileService.getUserData(uid);
        return {
          uid: {'name': data['name'] ?? '', 'username': data['username'] ?? ''},
        };
      }),
    );

    for (var map in results) {
      infoMap.addAll(map);
    }

    if (mounted) {
      setState(() {
        _friendsList = friendsList;
        _friendInfoMap = infoMap;
      });
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
      final imageUrl = await FirebaseStorageService.getProfileImageUrl(uid);
      fetchedFriends.add({'uid': uid, 'imageUrl': imageUrl ?? ''});
    }

    return fetchedFriends;
  }

  Future<void> _showChoosePinnedFriendsModal(BuildContext context) async {
    List<String> tempPinned = List<String>.from(_pinnedFriendUids);
    TextEditingController searchController = TextEditingController();
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredFriends = _friendsList.where((uid) {
              final info = _friendInfoMap[uid];
              if (info == null) return false;
              final name = info['name']?.toLowerCase() ?? '';
              final username = info['username']?.toLowerCase() ?? '';
              return name.contains(searchQuery) ||
                  username.contains(searchQuery);
            }).toList();

            filteredFriends.sort((a, b) {
              final aPinned = tempPinned.contains(a) ? 0 : 1;
              final bPinned = tempPinned.contains(b) ? 0 : 1;
              return aPinned.compareTo(bPinned);
            });

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    _buildModalHeader(searchController, (query) {
                      setModalState(() {
                        searchQuery = query.trim().toLowerCase();
                      });
                    }),
                    _buildFriendsList(
                      filteredFriends,
                      tempPinned,
                      setModalState,
                    ),
                    _buildSaveButton(context, tempPinned),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      PopupNotificationService.hide();
    });
  }

  Widget _buildModalHeader(
    TextEditingController searchController,
    Function(String) onSearchChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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

          DefaultSearchBar(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList(
    List<String> filteredFriends,
    List<String> tempPinned,
    StateSetter setModalState,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView.builder(
          itemCount: filteredFriends.length,
          itemBuilder: (context, index) {
            final uid = filteredFriends[index];
            final info = _friendInfoMap[uid] ?? {};
            final name = info['name'] ?? '';
            final username = info['username'] ?? '';
            final isPinned = tempPinned.contains(uid);

            return FutureBuilder<String?>(
              future: FirebaseStorageService.getProfileImageUrl(uid),
              builder: (context, snapshot) {
                return ListTile(
                  leading: UserRoundAvatar(
                    userId: uid,
                    radius: 24,
                    //  fallbackAsset: 'assets/images/icons/prof_page/no_photo.png',
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
                    activeColor: const Color.fromARGB(255, 86, 201, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: (val) => _handleCheckboxChange(
                      val,
                      uid,
                      tempPinned,
                      setModalState,
                      context,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _handleCheckboxChange(
    bool? val,
    String uid,
    List<String> tempPinned,
    StateSetter setModalState,
    BuildContext context,
  ) {
    if (val == true) {
      if (tempPinned.length >= 3) {
        PopupNotificationService.showError(
          context: context,
          message: 'You can only pin up to 3 friends',
          position: NotificationPosition.top,
        );
        return;
      }
      if (!tempPinned.contains(uid)) {
        setModalState(() {
          tempPinned.add(uid);
        });
      }
    } else {
      setModalState(() {
        tempPinned.remove(uid);
      });
    }
  }

  Widget _buildSaveButton(BuildContext context, List<String> tempPinned) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 86, 201, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: () async {
            Navigator.pop(context);
            _setPinnedFriends(tempPinned);
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              PopupNotificationService.showSuccess(
                context: this.context,
                message: 'Pinned friends updated successfully!',
                position: NotificationPosition.top,
              );
            }
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
      ),
    );
  }

  Widget _buildFriendWidget(String uid, double size, {String? imageUrl}) {
    ImageProvider avatar;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      avatar = NetworkImage(imageUrl);
    } else {
      avatar = const AssetImage('assets/images/icons/prof_page/no_photo.png');
    }

    return GestureDetector(
      onTap: () => _showFriendOptionsModal(context, uid),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        width: size,
        height: size,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          color: Color.fromARGB(255, 244, 188, 0),
        ),
        clipBehavior: Clip.hardEdge,
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(image: avatar, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(double size) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        color: Colors.grey[300],
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _showFriendOptionsModal(
    BuildContext context,
    String friendUid,
  ) async {
    final userProfileService = Provider.of<UserDataService>(
      context,
      listen: false,
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
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
                        child: FutureBuilder<Map<String, String>>(
                          future: userProfileService.getUserData(friendUid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            } else if (snapshot.hasError || !snapshot.hasData) {
                              return const DefaultText('Unknown');
                            } else {
                              final name = snapshot.data!['name'] ?? 'Unknown';
                              return DefaultText(name);
                            }
                          },
                        ),
                      ),
                    ),
                    Container(
                      width: 264,
                      height: 1,
                      color: const Color.fromARGB(255, 86, 201, 46),
                    ),
                    _buildModalOption(
                      text: 'View profile page',
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                YourFriendProfilePage(friendUid: friendUid),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 264,
                      height: 2,
                      color: const Color.fromARGB(255, 211, 211, 211),
                    ),
                    _buildModalOption(
                      text: 'Choose pinned friends',
                      onPressed: () {
                        Navigator.pop(context);
                        _showChoosePinnedFriendsModal(context);
                      },
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

  Widget _buildModalOption({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 37,
      width: 264,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: 'Irina',
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Center(child: Text(text)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final size = screenWidth / 3.8;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserUid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final friendsList = List<String>.from(data['friends'] ?? []);

        if (friendsList.isEmpty) {
          return const SizedBox(
            height: 70,
            child: Align(
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

        const listEquality = ListEquality<String>();
        if (!listEquality.equals(_friendsList, friendsList)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateFriendsData(friendsList);
          });
        }

        if (_isLoadingPinned || _friendInfoMap.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final validPinnedUids = _pinnedFriendUids
            .where((uid) => friendsList.contains(uid))
            .toList();

        List<Widget> friendWidgets = [];
        for (final uid in validPinnedUids) {
          final imageUrl = _pinnedFriendImages[uid];
          friendWidgets.add(_buildFriendWidget(uid, size, imageUrl: imageUrl));
        }

        final nonPinnedFriends = friendsList
            .where((uid) => !validPinnedUids.contains(uid))
            .toList();
        final slotsLeft = 3 - friendWidgets.length;

        if (friendWidgets.isEmpty && nonPinnedFriends.isNotEmpty) {
          return FutureBuilder<List<Map<String, String>>>(
            future: _getFriendsData(nonPinnedFriends, max: 3),
            builder: (context, friendSnapshot) {
              if (friendSnapshot.connectionState == ConnectionState.waiting) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => _buildLoadingWidget(size),
                  ),
                );
              }

              if (friendSnapshot.hasData) {
                final friendsData = friendSnapshot.data!;
                final widgets = friendsData.map((friend) {
                  return _buildFriendWidget(
                    friend['uid']!,
                    size,
                    imageUrl: friend['imageUrl'],
                  );
                }).toList();

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: widgets,
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (index) => _buildLoadingWidget(size),
                ),
              );
            },
          );
        }

        if (slotsLeft > 0 && nonPinnedFriends.isNotEmpty) {
          return FutureBuilder<List<Map<String, String>>>(
            future: _getFriendsData(nonPinnedFriends, max: slotsLeft),
            builder: (context, friendSnapshot) {
              List<Widget> currentWidgets = List.from(friendWidgets);

              if (friendSnapshot.hasData) {
                final friendsData = friendSnapshot.data!;
                for (var friend in friendsData) {
                  currentWidgets.add(
                    _buildFriendWidget(
                      friend['uid']!,
                      size,
                      imageUrl: friend['imageUrl'],
                    ),
                  );
                }
              } else {
                currentWidgets.addAll(
                  List.generate(
                    slotsLeft,
                    (index) => _buildLoadingWidget(size),
                  ),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: currentWidgets.take(3).toList(),
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

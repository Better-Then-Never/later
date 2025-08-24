import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:later/services/auth/user_services.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:later/views/widgets/your_friend_profile_page.dart';

class MyFriendsPage extends StatefulWidget {
  const MyFriendsPage({super.key});

  @override
  State<MyFriendsPage> createState() => _MyFriendsPageState();
}

class _MyFriendsPageState extends State<MyFriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  static final Map<String, String?> _imageUrlCache = {};

  List<DocumentSnapshot> _allFriendsDocs = [];
  bool _isLoadingFriends = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final newQuery = _searchController.text.trim();
      if (newQuery != _searchQuery) {
        setState(() {
          _searchQuery = newQuery;
        });
      }
    });
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    final userService = Provider.of<UserService>(context, listen: false);
    final currentUid = userService.uid;
    if (currentUid == null) {
      setState(() {
        _allFriendsDocs = [];
        _isLoadingFriends = false;
      });
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .get();
    final data = userDoc.data() ?? {};
    final friendsList = List<String>.from(data['friends'] ?? []);
    if (friendsList.isEmpty) {
      setState(() {
        _allFriendsDocs = [];
        _isLoadingFriends = false;
      });
      return;
    }
    final friendsDocs = await Future.wait(
      friendsList.map(
        (friendId) =>
            FirebaseFirestore.instance.collection('users').doc(friendId).get(),
      ),
    );
    setState(() {
      _allFriendsDocs = friendsDocs;
      _isLoadingFriends = false;
    });
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          Container(
            width: screenWidth,
            height: screenHeight * 0.18,
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
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'My friends',
                          style: TextStyle(
                            fontSize: screenWidth * 0.10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 1),
                        Padding(
                          padding: EdgeInsets.only(
                            left: screenWidth * 0.05,
                            right: screenWidth * 0.05,
                            top: 0,
                            bottom: screenHeight * 0.01,
                          ),
                          child: Container(
                            height: 45,
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
                                    width: screenWidth * 0.07,
                                    height: screenWidth * 0.07,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: "Find my friends...",
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Irina',
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                  ),
                                  child: Image.asset(
                                    'assets/images/icons/friends_page/open_camera.png',
                                    width: screenWidth * 0.08,
                                    height: screenWidth * 0.08,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 65,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
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
            child: _isLoadingFriends
                ? Center(child: CircularProgressIndicator())
                : _allFriendsDocs.isEmpty
                ? Center(
                    child: Text(
                      'No friends added yet',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Irina',
                        color: Colors.black,
                      ),
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final filteredFriends = _allFriendsDocs.where((doc) {
                        final friendData =
                            doc.data() as Map<String, dynamic>? ?? {};
                        final friendName = friendData['name'] ?? '';
                        final friendUsername = friendData['username'] ?? '';
                        final query = _searchQuery.toLowerCase();
                        return friendName.toLowerCase().contains(query) ||
                            friendUsername.toLowerCase().contains(query);
                      }).toList();

                      final Map<String, List<DocumentSnapshot>> grouped = {};
                      for (var doc in filteredFriends) {
                        final friendData =
                            doc.data() as Map<String, dynamic>? ?? {};
                        final friendName = (friendData['name'] ?? '')
                            .toString();
                        if (friendName.isEmpty) continue;
                        final letter = friendName[0].toUpperCase();
                        grouped.putIfAbsent(letter, () => []).add(doc);
                      }
                      final sortedKeys = grouped.keys.toList()..sort();

                      if (filteredFriends.isEmpty) {
                        return Center(
                          child: Text(
                            'No friends match your search',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Irina',
                              color: Colors.black,
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: sortedKeys.length,
                        itemBuilder: (context, groupIndex) {
                          final letter = sortedKeys[groupIndex];
                          final group = grouped[letter]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: 0,
                                ),
                                child: Text(
                                  letter,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.055,
                                    fontFamily: 'Irina',
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.03,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      spreadRadius: 1,
                                      blurRadius: 9,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    for (int i = 0; i < group.length; i++) ...[
                                      _FriendRow(
                                        friendData:
                                            group[i].data()
                                                as Map<String, dynamic>? ??
                                            {},
                                        screenWidth: screenWidth,
                                        getImageUrl: _getImageUrl,
                                      ),
                                      if (i < group.length - 1)
                                        const Divider(
                                          height: 1,
                                          thickness: 1,
                                          indent: 0,
                                          endIndent: 0,
                                          color: Color.fromARGB(
                                            255,
                                            211,
                                            211,
                                            211,
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  final Map<String, dynamic> friendData;
  final double screenWidth;
  final Future<String?> Function(String userId) getImageUrl;

  const _FriendRow({
    required this.friendData,
    required this.screenWidth,
    required this.getImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final friendName = friendData['name'] ?? '';
    final friendUsername = friendData['username'] ?? '';
    final friendId =
        friendData['uid'] ?? friendData['id'] ?? friendData['userId'];
    return FutureBuilder<String?>(
      future: friendId != null ? getImageUrl(friendId) : Future.value(null),
      builder: (context, snapshot) {
        ImageProvider avatar;
        if (snapshot.connectionState == ConnectionState.waiting) {
          avatar = AssetImage('assets/images/icons/navbar/icon-profile.png');
        } else if (snapshot.hasData &&
            snapshot.data != null &&
            snapshot.data!.isNotEmpty) {
          avatar = NetworkImage(snapshot.data!);
        } else {
          avatar = AssetImage('assets/images/icons/navbar/icon-profile.png');
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            splashFactory: NoSplash.splashFactory,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            borderRadius: BorderRadius.circular(25),
            onTap: friendId != null
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            YourFriendProfilePage(), // (userId: friendId) ADD LOGIC HERE
                      ),
                    );
                  }
                : null,
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(
                vertical: 0,
                horizontal: screenWidth * 0.02,
              ),
              leading: CircleAvatar(
                radius: screenWidth * 0.07,
                backgroundImage: avatar,
                backgroundColor: Colors.grey[200],
              ),
              title: Text(
                friendName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenWidth * 0.045,
                  fontFamily: 'Irina',
                  color: Colors.black,
                ),
              ),
              subtitle: Text(
                '@$friendUsername',
                style: TextStyle(
                  fontSize: screenWidth * 0.040,
                  fontFamily: 'Irina',
                  color: Color.fromARGB(255, 94, 94, 94),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

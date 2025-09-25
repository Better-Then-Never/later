import 'package:flutter/material.dart';
import 'package:later/services/firebase_storage_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';
import 'package:later/views/widgets/_common/default_elements/default_search_bar.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/views/widgets/_common/premade_buttons/go_back_button.dart';
import 'package:later/views/widgets/user/user_list_tile.dart';
import 'package:provider/provider.dart';
import 'package:later/views/pages/friends_pages/your_friend_profile_page.dart';
import 'package:later/views/pages/core_pages/qr_code_scanner_page.dart';

//TODO: Refactor

class MyFriendsPage extends StatefulWidget {
  const MyFriendsPage({super.key});

  @override
  State<MyFriendsPage> createState() => _MyFriendsPageState();
}

class _MyFriendsPageState extends State<MyFriendsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _allFriends = [];
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
    final profileService = Provider.of<UserDataService>(context, listen: false);

    final currentUid = profileService.currentLoggedInUid;
    if (currentUid == 'No User') {
      setState(() {
        _allFriends = [];
        _isLoadingFriends = false;
      });
      return;
    }

    try {
      final friendsList = await profileService.getUserFriends(currentUid);

      if (friendsList.isEmpty) {
        setState(() {
          _allFriends = [];
          _isLoadingFriends = false;
        });
        return;
      }

      final friends = await Future.wait(
        friendsList.map((friendUid) async {
          final data = await profileService.getUserData(friendUid);
          final imageUrl = await FirebaseStorageService.getProfileImageUrl(
            friendUid,
          );

          return {
            'id': friendUid,
            'name': data['name'] ?? '',
            'username': data['username'] ?? '',
            'imageUrl': imageUrl,
          };
        }),
      );

      setState(() {
        _allFriends = friends;
        _isLoadingFriends = false;
      });
    } catch (e) {
      setState(() {
        _allFriends = [];
        _isLoadingFriends = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          PageHeader(
            mainText: 'My friends',
            leadingButton: GoBackButton(context: context),
            searchBar: DefaultSearchBar(
              controller: _searchController,
              hintText: 'Find my friends',
              trailingButton: DefaultIconButton(
                onTap: () => QRScannerPage.open(context),
                assetPath: 'assets/images/icons/friends_page/qr_scan.png',
                size: screenWidth * 0.09,
              ),
            ),
          ),

          Expanded(
            child: _isLoadingFriends
                ? Center(child: CircularProgressIndicator())
                : _allFriends.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/icons/prof_page/friend_search.png',
                          width: 72,
                          height: 72,
                          color: Colors.black,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No friends added yet',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Irina',
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                : Builder(
                    builder: (context) {
                      final filteredFriends = _allFriends.where((friend) {
                        final friendName = friend['name'] ?? '';
                        final friendUsername = friend['username'] ?? '';
                        final query = _searchQuery.toLowerCase();
                        return friendName.toLowerCase().contains(query) ||
                            friendUsername.toLowerCase().contains(query);
                      }).toList();

                      final Map<String, List<Map<String, dynamic>>> grouped =
                          {};
                      for (var friend in filteredFriends) {
                        final friendName = friend['name'] ?? '';
                        if (friendName.isEmpty) continue;
                        final letter = friendName[0].toUpperCase();
                        grouped.putIfAbsent(letter, () => []).add(friend);
                      }
                      final sortedKeys = grouped.keys.toList()..sort();

                      if (filteredFriends.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/icons/prof_page/friend_search.png',
                                width: 72,
                                height: 72,
                                color: Colors.black,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No friends match your search',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Irina',
                                  color: Colors.black,
                                ),
                              ),
                            ],
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
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          splashFactory: NoSplash.splashFactory,
                                          overlayColor: WidgetStateProperty.all(
                                            Colors.transparent,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    YourFriendProfilePage(
                                                      friendUid: group[i]['id'],
                                                    ),
                                              ),
                                            ).then((result) {
                                              if (result == 'friend_removed') {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Friend removed successfully',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontFamily: 'Irina',
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      backgroundColor:
                                                          const Color.fromARGB(
                                                            255,
                                                            86,
                                                            201,
                                                            46,
                                                          ),
                                                      duration: const Duration(
                                                        seconds: 3,
                                                      ),
                                                      behavior: SnackBarBehavior
                                                          .floating,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                                _fetchFriends();
                                              }
                                            });
                                          },
                                          child: UserListTile(
                                            name: group[i]['name'] ?? '',
                                            username:
                                                group[i]['username'] ?? '',
                                            imageUrl: group[i]['imageUrl'],
                                            screenWidth: screenWidth,
                                          ),
                                        ),
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

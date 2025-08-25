import 'package:flutter/material.dart';
import 'package:later/services/auth/friend_search.dart';
import 'package:provider/provider.dart';
import 'package:later/services/auth/user_services.dart';
import 'package:later/views/widgets/overlay_notification.dart';

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  static final Set<String> _hiddenUserIds = {};
  static final Set<String> _addedFriendIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    OverlayNotification.hide();
    _searchController.dispose();

    // Clear the static sets when leaving the page
    _hiddenUserIds.clear();
    _addedFriendIds.clear();

    super.dispose();
  }

  Future<void> _refreshPage() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Clear all tracking sets
      _hiddenUserIds.clear();
      _addedFriendIds.clear();

      // Clear search query
      _searchController.clear();

      // Refresh user service friends list
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.refreshFriends();

      // Add a small delay to show the loading state
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _searchQuery = '';
          _isRefreshing = false;
        });

        OverlayNotification.showInfo(
          context: context,
          message: 'Friends list refreshed!',
          position: NotificationPosition.center,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        OverlayNotification.showError(
          context: context,
          message: 'Failed to refresh friends list',
          position: NotificationPosition.center,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async {
        // Also clear when back button is pressed
        _hiddenUserIds.clear();
        _addedFriendIds.clear();
        return true;
      },
      child: Scaffold(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Add friends',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.10,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Irina',
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(
                                width: 12,
                              ), // Space between text and button
                              GestureDetector(
                                onTap: _isRefreshing ? null : _refreshPage,
                                child: Container(
                                  padding: EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                      255,
                                      33,
                                      150,
                                      243,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: _isRefreshing
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          Icons.refresh,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ],
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
                                        hintText: "Search by nickname...",
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
                        // Clear sets before navigating back
                        _hiddenUserIds.clear();
                        _addedFriendIds.clear();
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
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.015,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(0xFFEAEAEA),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Image.asset(
                              'assets/images/icons/friends_page/friend_book.png',
                              width: 32,
                              height: 32,
                            ),
                          ),
                          Text(
                            'Invite friends',
                            style: TextStyle(
                              fontFamily: 'Irina',
                              fontSize: 19,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(0xFFEAEAEA),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Image.asset(
                              'assets/images/icons/friends_page/friend_request.png',
                              width: 32,
                              height: 32,
                            ),
                          ),
                          Text(
                            'Requests',
                            style: TextStyle(
                              fontFamily: 'Irina',
                              fontSize: 19,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: screenWidth * 0.07),
                child: Text(
                  'Make friends',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Irina',
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.01),
                  child: Column(
                    children: [
                      FriendsSearchWidget(
                        onAddFriend: (userId) async {
                          try {
                            final userService = Provider.of<UserService>(
                              context,
                              listen: false,
                            );
                            await userService.addFriend(userId);
                            if (!mounted) return;

                            setState(() {
                              _addedFriendIds.add(userId);
                            });

                            OverlayNotification.showSuccess(
                              context: context,
                              message: 'Friend added!',
                              position: NotificationPosition.center,
                            );
                          } catch (e) {
                            if (!mounted) return;
                            OverlayNotification.showError(
                              context: context,
                              message: 'Failed to add friend',
                              position: NotificationPosition.center,
                            );
                          }
                        },
                        onRemoveFriend: (userId) {
                          setState(() {
                            _hiddenUserIds.add(userId);
                          });
                          OverlayNotification.showInfo(
                            context: context,
                            message: 'Suggested friend removed from the list!',
                            position: NotificationPosition.center,
                          );
                        },
                        hiddenUserIds: _hiddenUserIds,
                        addedFriendIds: _addedFriendIds,
                        searchQuery: _searchQuery,
                      ),
                      SizedBox(height: screenHeight * 0.12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

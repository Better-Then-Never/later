import 'package:flutter/material.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/pages/friends_pages/friend_requests_page.dart';
import 'package:provider/provider.dart';
import 'package:later/views/pages/core_pages/qr_code_scanner_page.dart';
import 'package:later/views/pages/friends_pages/invite_friends_page.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/views/widgets/_common/default_elements/default_search_bar.dart';
import 'package:later/views/widgets/_common/premade_buttons/go_back_button.dart';
import 'package:later/views/widgets/_common/premade_buttons/refresh_button.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';
import 'package:later/views/widgets/friends/suggested_friends_list.dart';

// TODO: Refactor

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  static final Set<String> _hiddenUserIds = {};
  static final Set<String> _sentRequestIds = {};
  final UserFriendsService _requestService = UserFriendsService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;
  int _refreshKey = 0;

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
    PopupNotificationService.hide();
    _searchController.dispose();
    _hiddenUserIds.clear();
    _sentRequestIds.clear();
    super.dispose();
  }

  Future<void> _refreshPage() async {
    if (!mounted) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      _sentRequestIds.clear();
      _searchController.clear();

      final userFriendsService = Provider.of<UserFriendsService>(
        context,
        listen: false,
      );
      await userFriendsService.refreshFriends();

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _searchQuery = '';
          _isRefreshing = false;
          _refreshKey++;
        });

        PopupNotificationService.showInfo(
          context: context,
          message: 'Friends list refreshed!',
          position: NotificationPosition.bottom,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });

        PopupNotificationService.showError(
          context: context,
          message: 'Failed to refresh friends list',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        _hiddenUserIds.clear();
        _sentRequestIds.clear();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F6),
        body: Column(
          children: [
            PageHeader(
              mainText: 'Add Friends',
              leadingButton: GoBackButton(context: context),
              trailingButton: RefreshButton(
                size: 40,
                isRefreshing: _isRefreshing,
                onTap: _refreshPage,
              ),
              searchBar: DefaultSearchBar(
                controller: _searchController,
                hintText: 'Search by nickname...',
                trailingButton: DefaultIconButton(
                  onTap: () => QRScannerPage.open(context),
                  assetPath: 'assets/images/icons/friends_page/qr_scan.png',
                  size: screenWidth * 0.09,
                ),
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
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InviteFriendsPage(),
                          ),
                        );
                      },
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
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FriendRequestsPage(
                              onFriendListChanged: () {
                                if (mounted) {
                                  setState(() {
                                    _refreshKey++;
                                    _sentRequestIds.clear();
                                  });

                                  final userFriendsService =
                                      Provider.of<UserFriendsService>(
                                        context,
                                        listen: false,
                                      );

                                  userFriendsService.refreshFriends();
                                }
                              },
                            ),
                          ),
                        );

                        if (result == true && mounted) {
                          setState(() {
                            _refreshKey++;
                            _sentRequestIds.clear();
                          });

                          if (context.mounted) {
                            PopupNotificationService.showSuccess(
                              context: context,
                              message: 'Friends list updated!',
                              position: NotificationPosition.bottom,
                            );
                          }
                        }
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Color(0xFFEAEAEA),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/icons/friends_page/friend_request.png',
                                    width: 32,
                                    height: 32,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Requests',
                                    style: TextStyle(
                                      fontFamily: 'Irina',
                                      fontSize: 19,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                ],
                              ),
                            ),
                            StreamBuilder<int>(
                              stream:
                                  UserFriendsService.getReceivedRequestsCount(
                                    Provider.of<UserDataService>(
                                      context,
                                      listen: false,
                                    ).currentLoggedInUid,
                                  ),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData || snapshot.data == 0) {
                                  return SizedBox.shrink();
                                }

                                final count = snapshot.data!;
                                final displayCount = count > 99
                                    ? '99+'
                                    : count.toString();

                                return Positioned(
                                  top: 15,
                                  right: 12,
                                  child: Container(
                                    constraints: BoxConstraints(minWidth: 20),
                                    height: 20,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        displayCount,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Irina',
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
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
                      SuggestedFriendsList(
                        key: ValueKey(_refreshKey),
                        onSendRequest: (userId) async {
                          if (!mounted) return;

                          final userService = Provider.of<UserDataService>(
                            context,
                            listen: false,
                          );

                          try {
                            final requestExists = await _requestService
                                .requestExists(
                                  userService.currentLoggedInUid,
                                  userId,
                                );

                            if (!mounted) {
                              return;
                            }
                            if (requestExists) {
                              if (context.mounted) {
                                PopupNotificationService.showInfo(
                                  context: context,
                                  message: 'Friend request already exists',
                                  position: NotificationPosition.bottom,
                                );
                              }
                              return;
                            }

                            await _requestService.sendFriendRequest(
                              userService.currentLoggedInUid,
                              userId,
                            );

                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _sentRequestIds.add(userId);
                            });

                            if (context.mounted) {
                              PopupNotificationService.showSuccess(
                                context: context,
                                message: 'Friend request sent!',
                                position: NotificationPosition.bottom,
                              );
                            }
                          } catch (e) {
                            if (!mounted) {
                              return;
                            }
                            if (context.mounted) {
                              PopupNotificationService.showError(
                                context: context,
                                message: 'Failed to send friend request',
                                position: NotificationPosition.bottom,
                              );
                            }
                          }
                        },
                        onRemoveFriend: (userId) {
                          if (!mounted) return;
                          setState(() {
                            _hiddenUserIds.add(userId);
                          });
                          if (context.mounted) {
                            PopupNotificationService.showInfo(
                              context: context,
                              message:
                                  'Suggested friend removed from the list!',
                              position: NotificationPosition.bottom,
                            );
                          }
                        },
                        hiddenUserIds: _hiddenUserIds,
                        sentRequestIds: _sentRequestIds,
                        searchQuery: _searchQuery,
                        onStateChanged: () {
                          setState(() {
                            _refreshKey++;
                          });
                        },
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

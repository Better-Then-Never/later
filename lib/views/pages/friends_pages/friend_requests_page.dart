import 'package:flutter/material.dart';
import 'package:later/controllers/friend_requests_page_controller.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/views/widgets/_common/premade_buttons/go_back_button.dart';
import 'package:later/views/widgets/friends/friend_requests_page/friend_requests_received_list.dart';
import 'package:later/views/widgets/friends/friend_requests_page/friend_requests_sent_list.dart';
import 'package:later/views/widgets/friends/friend_requests_page/friend_requests_toggle_button.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/services/user_data_service.dart';

class FriendRequestsPage extends StatefulWidget {
  const FriendRequestsPage({super.key});

  @override
  State<FriendRequestsPage> createState() => _FriendRequestsPageState();
}

class _FriendRequestsPageState extends State<FriendRequestsPage> {
  late final UserFriendsService _userFriendsService;
  late final UserDataService _userDataService;
  late final FriendRequestsPageController _controller;

  bool _showReceived = true;

  @override
  void initState() {
    super.initState();
    _userFriendsService = Provider.of<UserFriendsService>(
      context,
      listen: false,
    );
    _userDataService = Provider.of<UserDataService>(context, listen: false);

    _controller = FriendRequestsPageController(
      friendsService: _userFriendsService,
      userService: _userDataService,
    );
  }

  @override
  void dispose() {
    PopupNotificationService.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          PageHeader(
            mainText: 'Friend Requests',
            leadingButton: GoBackButton(context: context),
            actionButtonsRow: Row(
              children: [
                FriendRequestsToggleButton(
                  onTap: () => setState(() => _showReceived = true),
                  text: 'Received',
                  isSelected: _showReceived,
                ),
                const SizedBox(width: 12),
                FriendRequestsToggleButton(
                  onTap: () => setState(() => _showReceived = false),
                  text: 'Sent',
                  isSelected: !_showReceived,
                ),
              ],
            ),
          ),
          Expanded(
            child: _showReceived
                ? FriendRequestsReceivedList(
                    screenWidth: screenWidth,
                    controller: _controller,
                    userDataService: _userDataService,
                  )
                : FriendRequestsSentList(
                    screenWidth: screenWidth,
                    controller: _controller,
                    userDataService: _userDataService,
                  ),
          ),
        ],
      ),
    );
  }
}

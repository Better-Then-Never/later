import 'package:flutter/material.dart';
import 'package:later/controllers/page_controllers/friends/add_friends_page_controller.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/friends/add_friends_page/add_friends_action_buttons_row.dart';
import 'package:provider/provider.dart';
import 'package:later/views/pages/core_pages/qr_code_scanner_page.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/views/widgets/_common/default_elements/default_search_bar.dart';
import 'package:later/views/widgets/_common/premade_buttons/go_back_button.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';
import 'package:later/views/widgets/friends/add_friends_page/suggested_friends_list.dart';

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  late final UserFriendsService _userFriendsService;
  late final UserDataService _userDataService;
  late final AddFriendsPageController _controller;

  @override
  void initState() {
    super.initState();

    _userFriendsService = Provider.of<UserFriendsService>(
      context,
      listen: false,
    );

    _userDataService = Provider.of<UserDataService>(context, listen: false);

    _controller = AddFriendsPageController(
      friendsService: _userFriendsService,
      userService: _userDataService,
    );

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
            mainText: 'Add Friends',
            leadingButton: GoBackButton(context: context),
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

          AddFriendsActionButtonsRow(),

          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.07),
              child: DefaultText(
                'Make friends',
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Expanded(
            child: SafeArea(
              child: SingleChildScrollView(
                child: SuggestedFriendsList(
                  onSendRequest: (userId) {
                    _controller.sendFriendRequest(
                      userId: userId,
                      context: context,
                    );
                  },
                  onRemoveFriend: (userId) {
                    _controller.removeSuggestedFriend(
                      userId: userId,
                      context: context,
                    );
                  },
                  searchQuery: _searchQuery,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

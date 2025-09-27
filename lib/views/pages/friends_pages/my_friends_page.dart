import 'package:flutter/material.dart';
import 'package:later/controllers/page_controllers/friends/my_friends_page_controller.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/views/widgets/_common/default_buttons/default_icon_button.dart';
import 'package:later/views/widgets/_common/default_elements/default_empty_inbox_info.dart';
import 'package:later/views/widgets/_common/default_elements/default_search_bar.dart';
import 'package:later/views/widgets/_common/default_elements/page_header.dart';
import 'package:later/views/widgets/_common/premade_buttons/go_back_button.dart';
import 'package:later/views/widgets/friends/my_friends_page/my_friends_grouped_by_letter_list.dart';
import 'package:provider/provider.dart';
import 'package:later/views/pages/core_pages/qr_code_scanner_page.dart';

class MyFriendsPage extends StatefulWidget {
  const MyFriendsPage({super.key});

  @override
  State<MyFriendsPage> createState() => _MyFriendsPageState();
}

class _MyFriendsPageState extends State<MyFriendsPage> {
  final TextEditingController _searchController = TextEditingController();

  late final MyFriendsPageController _controller;

  @override
  void initState() {
    super.initState();

    final friendsService = Provider.of<UserFriendsService>(
      context,
      listen: false,
    );
    final userService = Provider.of<UserDataService>(context, listen: false);

    _controller = MyFriendsPageController(
      friendsService: friendsService,
      userService: userService,
    );

    _searchController.addListener(() {
      _controller.updateSearchQuery(_searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
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
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final friends = _controller.filteredFriends;

                if (friends.isEmpty) {
                  return DefaultEmptyInboxInfo(
                    message: _controller.searchQuery.isEmpty
                        ? 'No friends added yet'
                        : 'No friends match your search',
                    assetPath:
                        'assets/images/icons/prof_page/friend_search.png',
                  );
                }

                final grouped = _controller.groupedFilteredFriends;

                return MyFriendsGroupedByLetterList(
                  groupedFriends: grouped,
                  screenWidth: screenWidth,
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

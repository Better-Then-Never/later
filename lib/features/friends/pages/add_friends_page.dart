import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../data/repositories/repositories.dart';
import '../../../services/popup_notification_service.dart';
import '../../../views/pages/core_pages/qr_code_scanner_page.dart';
import '../../../views/widgets/_common/default_buttons/default_icon_button.dart';
import '../../../views/widgets/_common/default_elements/default_search_bar.dart';
import '../../../views/widgets/_common/default_elements/default_text.dart';
import '../../../views/widgets/_common/default_elements/page_header.dart';
import '../../../views/widgets/_common/premade_buttons/go_back_button.dart';
import '../../users/user_directory.dart';
import '../friend_actions.dart';
import '../friend_suggestions_controller.dart';
import '../widgets/add_friends/add_friends_action_buttons_row.dart';
import '../widgets/add_friends/suggested_friends_list.dart';

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  final _searchController = TextEditingController();
  late final FriendSuggestionsController _suggestions;

  @override
  void initState() {
    super.initState();
    _suggestions = FriendSuggestionsController(
      users: context.read<UserRepository>(),
      directory: context.read<UserDirectory>(),
    );
    _searchController.addListener(
      () => _suggestions.search(_searchController.text),
    );
  }

  @override
  void dispose() {
    PopupNotificationService.hide();
    _searchController.dispose();
    _suggestions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final actions = FriendActions(
      context,
      position: NotificationPosition.bottom,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          PageHeader(
            mainText: 'Add Friends',
            leadingButton: GoBackButton(context: context),
            searchBar: DefaultSearchBar(
              controller: _searchController,
              hintText: 'Search by tag',
              trailingButton: DefaultIconButton(
                onTap: () => QRScannerPage.open(context),
                assetPath: AppIcons.friendsQrScan,
                size: screenWidth * 0.09,
              ),
            ),
          ),
          const AddFriendsActionButtonsRow(),
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
          Flexible(
            child: SafeArea(
              top: false,
              child: SuggestedFriendsList(
                controller: _suggestions,
                actions: actions,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

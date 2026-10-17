import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../data/repositories/repositories.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';
import '../../../shared/widgets/default_search_bar.dart';
import '../../../shared/widgets/default_text.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/buttons/go_back_button.dart';
import '../../users/user_directory.dart';
import '../friend_actions.dart';
import '../friend_suggestions_controller.dart';
import '../friends_store.dart';
import '../../../core/config/feature_flags.dart';
import '../../../data/services/contacts_service.dart';
import '../widgets/add_friends/add_friends_action_buttons_row.dart';
import '../widgets/add_friends/from_contacts.dart';
import '../widgets/add_friends/suggested_friends_list.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key, this.query = ''});

  /// Searched right away (from the chats' "Find people").
  final String query;

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  late final _searchController = TextEditingController(text: widget.query);
  late final FriendSuggestionsController _suggestions;

  @override
  void initState() {
    super.initState();
    _suggestions = FriendSuggestionsController(
      users: context.read<UserRepository>(),
      directory: context.read<UserDirectory>(),
      friends: context.read<FriendsStore>(),
    );
    _searchController.addListener(
      () => _suggestions.search(_searchController.text),
    );
    if (widget.query.isNotEmpty) _suggestions.search(widget.query);
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
      backgroundColor: context.palette.background,
      body: Column(
        children: [
          PageHeader(
            mainText: context.l10n.friendsAddTitle,
            leadingButton: GoBackButton(context: context),
            searchBar: DefaultSearchBar(
              controller: _searchController,
              hintText: context.l10n.friendsSearchPeopleHint,
              trailingButton: DefaultIconButton(
                onTap: () => AppRoutes.scanProfileQr(context),
                assetPath: AppIcons.friendsQrScan,
                semanticLabel: context.l10n.friendsQrTitle,
                size: screenWidth * 0.09,
              ),
            ),
          ),
          const AddFriendsActionButtonsRow(),
          if (FeatureFlags.contactSuggestions && ContactsService.isSupported)
            const FromContactsButton(),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.07),
              child: DefaultText(
                context.l10n.friendsMakeFriends,
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

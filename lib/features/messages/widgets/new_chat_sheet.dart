import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../../../shared/widgets/default_search_bar.dart';
import '../../../shared/widgets/user/user_list_tile.dart';
import '../../../shared/widgets/user/user_row_skeleton.dart';
import '../../friends/friends_store.dart';
import '../../users/user_directory.dart';

/// Bottom sheet listing the user's friends; picking one opens the chat.
class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  static Future<void> show(BuildContext context) => showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: AppColors.barrier,
    builder: (_) => const NewChatSheet(),
  );

  @override
  State<NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<NewChatSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(UserProfile? p) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    if (p == null) return false;
    return p.name.toLowerCase().contains(q) ||
        p.username.toLowerCase().contains(q);
  }

  /// Leaves the sheet first; the root navigator outlives it.
  void _closeThen(void Function(BuildContext root) open) {
    final root = AppRoutes.navigatorKey.currentContext;
    Navigator.of(context).pop();
    if (root != null) open(root);
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final friends = context.watch<FriendsStore>();
    final directory = context.watch<UserDirectory>();

    final ids = friends.friendIds.toList();
    final visible =
        [
          for (final id in ids)
            if (_matches(directory.profile(id))) id,
        ]..sort(
          (a, b) => (directory.profile(a)?.name ?? '').toLowerCase().compareTo(
            (directory.profile(b)?.name ?? '').toLowerCase(),
          ),
        );

    final Widget body;
    if (!friends.isLoaded) {
      body = Column(
        key: const ValueKey('loading'),
        children: [
          for (var i = 0; i < 3; i++)
            UserRowSkeleton(screenWidth: screen.width),
        ],
      );
    } else if (ids.isEmpty) {
      body = DefaultEmptyInboxInfo(
        key: const ValueKey('no-friends'),
        message: 'No friends yet',
        subtitle: 'Add some friends to start chatting!',
        assetPath: AppIcons.profileMyFriends,
        actionText: 'Find friends',
        onAction: () => _closeThen(AppRoutes.toAddFriends),
      );
    } else if (visible.isEmpty) {
      body = DefaultEmptyInboxInfo(
        key: const ValueKey('no-match'),
        message: 'No friends found',
        subtitle: 'Nothing matches "$_query"',
        assetPath: AppIcons.profileFriendSearch,
      );
    } else {
      body = ListView.builder(
        key: const ValueKey('list'),
        padding: EdgeInsets.fromLTRB(16, 4, 16, screen.height * 0.03),
        itemCount: visible.length,
        itemBuilder: (context, index) {
          final id = visible[index];
          final profile = directory.profile(id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DecoratedBox(
              decoration: BoxDecorations.whiteCard(),
              child: Semantics(
                button: true,
                label: 'Start chat with ${profile?.name ?? ''}',
                child: UserListTile(
                  uid: id,
                  name: profile?.name ?? '',
                  username: profile?.username ?? '',
                  screenWidth: screen.width,
                  onTap: () => _closeThen((root) => AppRoutes.toChat(root, id)),
                  trailing: Opacity(
                    opacity: 0.3,
                    child: Image.asset(
                      AppIcons.goHere,
                      width: screen.width * 0.09,
                      height: screen.width * 0.09,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      height: screen.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.pageBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Same header as the app's pages: white, rounded bottom.
          Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.all(Radius.circular(25)),
            ),
            padding: EdgeInsets.fromLTRB(
              screen.width * 0.04,
              screen.height * 0.02,
              screen.width * 0.04,
              0,
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Full width, so the close button sits at the edge.
                    const SizedBox(width: double.infinity),
                    Text(
                      'New Chat',
                      style: AppTextStyles.pageTitle(
                        screen,
                      ).copyWith(fontSize: screen.height * 0.03),
                    ),
                    Positioned(
                      right: 0,
                      child: DefaultIconButton(
                        onTap: () => Navigator.of(context).pop(),
                        assetPath: AppIcons.capsuleClose,
                        size: screen.width * 0.08,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screen.height * 0.015),
                DefaultSearchBar(
                  controller: _searchController,
                  hintText: 'Search friends',
                  onChanged: (value) => setState(() => _query = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: AppFadeSwitcher(child: body)),
        ],
      ),
    );
  }
}

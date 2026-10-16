import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../shared/widgets/user/user_round_avatar.dart';
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

  void _open(String friendUid) {
    // The sheet's context dies with the pop; the root navigator lives on.
    final root = AppRoutes.navigatorKey.currentContext;
    Navigator.of(context).pop();
    if (root != null) AppRoutes.toChat(root, friendUid);
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

    return Container(
      height: screen.height * 0.7,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screen.width * 0.04,
              vertical: screen.height * 0.02,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 40),
                Text(
                  'New Chat',
                  style: TextStyle(
                    fontSize: screen.height * 0.025,
                    fontWeight: FontWeight.bold,
                    fontFamily: kAppFontFamily,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screen.width * 0.04),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.search,
                      color: AppColors.grey600,
                      size: screen.width * 0.06,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search friends',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontFamily: kAppFontFamily,
                        fontSize: 18,
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: screen.height * 0.02),
          Expanded(
            child: !friends.isLoaded
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandGreen,
                    ),
                  )
                : ids.isEmpty
                ? _NoFriends(
                    onFindFriends: () {
                      final root = AppRoutes.navigatorKey.currentContext;
                      Navigator.of(context).pop();
                      if (root != null) AppRoutes.toAddFriends(root);
                    },
                  )
                : visible.isEmpty
                ? _CenteredInfo(
                    icon: Icons.search_off,
                    text: 'No friends match "$_query"',
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: screen.width * 0.02,
                    ),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final id = visible[index];
                      return _FriendRow(
                        friendUid: id,
                        profile: directory.profile(id),
                        onTap: () => _open(id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friendUid,
    required this.profile,
    required this.onTap,
  });

  final String friendUid;
  final UserProfile? profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final name = profile?.name ?? '';
    final username = profile?.username ?? '';

    return Semantics(
      label: 'Start chat with $name',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              UserRoundAvatar(userId: friendUid, radius: 25),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: screenHeight * 0.02,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (username.isNotEmpty)
                      Text(
                        '@$username',
                        style: TextStyle(
                          fontSize: screenHeight * 0.016,
                          color: AppColors.grey600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.grey400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoFriends extends StatelessWidget {
  const _NoFriends({required this.onFindFriends});

  final VoidCallback onFindFriends;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No friends yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.grey700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add some friends to start chatting!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.grey600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onFindFriends,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Find Friends',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredInfo extends StatelessWidget {
  const _CenteredInfo({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.grey400),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.grey600),
            ),
          ],
        ),
      ),
    );
  }
}

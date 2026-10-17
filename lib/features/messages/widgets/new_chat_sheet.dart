import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/entitlements_store.dart';
import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../../../shared/widgets/default_search_bar.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/user/user_round_avatar.dart';
import '../../../shared/widgets/user/user_list_tile.dart';
import '../../../shared/widgets/user/user_row_skeleton.dart';
import '../../friends/friends_store.dart';
import '../chats_store.dart';
import 'group_friends_picker.dart';
import '../../users/user_directory.dart';

/// "New group": the user picks a name and friends, the group is created
/// (the friends join as the server accepts them) and its chat opens.
Future<void> startGroup(BuildContext root) async {
  final l10n = root.l10n;
  final pick = await GroupFriendsPicker.show(
    root,
    title: l10n.messagesNewGroup,
    actionText: l10n.messagesGroupCreate,
    withName: true,
    // The creator counts too.
    room: EntitlementsStore.of(root).groupMembers - 1,
  );
  if (pick == null || !root.mounted) return;
  final (id, failure) = await root.read<ChatsStore>().createGroup(
    pick.name,
    pick.friends,
  );
  if (!root.mounted) return;
  if (id == null) {
    PopupNotificationService.showError(
      context: root,
      message: failure?.message ?? l10n.messagesGroupFailed,
      position: NotificationPosition.top,
    );
    return;
  }
  await AppRoutes.toGroupChat(root, id);
}

/// The first row of the sheet: start a group.
class _NewGroupRow extends StatelessWidget {
  const _NewGroupRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final radius = UserRoundAvatar.listRadius(screen.width);
    return Semantics(
      button: true,
      child: AppPressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            decoration: BoxDecorations.whiteCard(context),
            padding: EdgeInsets.symmetric(
              horizontal: screen.width * 0.03,
              vertical: 10,
            ),
            child: Row(
              children: [
                Container(
                  width: radius * 2,
                  height: radius * 2,
                  decoration: const BoxDecoration(
                    color: AppColors.brandGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const CustomPaint(painter: _PlusPainter()),
                ),
                SizedBox(width: screen.width * 0.04),
                Text(
                  context.l10n.messagesNewGroup,
                  style: AppTextStyles.listName(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlusPainter extends CustomPainter {
  const _PlusPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onAccent
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    final arm = size.width * 0.22;
    canvas
      ..drawLine(c - Offset(arm, 0), c + Offset(arm, 0), paint)
      ..drawLine(c - Offset(0, arm), c + Offset(0, arm), paint);
  }

  @override
  bool shouldRepaint(_PlusPainter old) => false;
}

/// Bottom sheet listing the user's friends; picking one opens the chat.
class NewChatSheet extends StatefulWidget {
  const NewChatSheet({super.key});

  static Future<void> show(BuildContext context) =>
      showEdgeSheet<void>(context, (_) => const NewChatSheet());

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
    final l10n = context.l10n;
    final palette = context.palette;

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
        message: l10n.messagesNewChatNoFriends,
        subtitle: l10n.messagesNewChatNoFriendsSubtitle,
        assetPath: AppIcons.profileMyFriends,
        actionText: l10n.messagesNewChatFindFriends,
        onAction: () => _closeThen(AppRoutes.toAddFriends),
      );
    } else if (visible.isEmpty) {
      body = DefaultEmptyInboxInfo(
        key: const ValueKey('no-match'),
        message: l10n.messagesNewChatNoMatch,
        subtitle: l10n.messagesNothingMatches(_query),
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
              decoration: BoxDecorations.whiteCard(context),
              child: Semantics(
                button: true,
                label: l10n.messagesStartChatWith(profile?.name ?? ''),
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
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSheets.radius),
        ),
      ),
      child: Column(
        children: [
          // Same header as the app's pages: white, rounded bottom.
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppSheets.radius),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              screen.width * 0.04,
              0,
              screen.width * 0.04,
              0,
            ),
            child: Column(
              children: [
                const SheetHandle(),
                SizedBox(height: screen.height * 0.008),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Full width, so the close button sits at the edge.
                    const SizedBox(width: double.infinity),
                    Text(
                      l10n.messagesNewChatTitle,
                      style: AppTextStyles.pageTitle(
                        context,
                      ).copyWith(fontSize: screen.height * 0.03),
                    ),
                    Positioned(
                      right: 0,
                      child: DefaultIconButton(
                        onTap: () => Navigator.of(context).pop(),
                        assetPath: AppIcons.capsuleClose,
                        semanticLabel: MaterialLocalizations.of(
                          context,
                        ).closeButtonTooltip,
                        size: screen.width * 0.08,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screen.height * 0.015),
                DefaultSearchBar(
                  controller: _searchController,
                  hintText: l10n.messagesNewChatSearchHint,
                  onChanged: (value) => setState(() => _query = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (friends.isLoaded && ids.isNotEmpty && _query.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _NewGroupRow(
                onTap: () => _closeThen((root) => unawaited(startGroup(root))),
              ),
            ),
          Expanded(child: AppFadeSwitcher(child: body)),
        ],
      ),
    );
  }
}

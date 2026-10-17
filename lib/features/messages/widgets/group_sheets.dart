import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/chat.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';
import '../../../shared/widgets/user/user_list_tile.dart';
import '../../friends/friends_store.dart';
import '../../users/user_directory.dart';

/// Who is in a group; tapping someone opens their profile.
class GroupMembersSheet extends StatelessWidget {
  const GroupMembersSheet({super.key, required this.members, this.me});

  final List<String> members;
  final String? me;

  static Future<void> show(
    BuildContext context, {
    required List<String> members,
    String? me,
  }) => showEdgeSheet<void>(
    context,
    (_) => GroupMembersSheet(members: members, me: me),
  );

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final directory = context.watch<UserDirectory>();
    final friends = context.watch<FriendsStore>();
    final palette = context.palette;
    final l10n = context.l10n;
    // The user first, then by name.
    final sorted = [...members]
      ..sort((a, b) {
        if (a == me) return -1;
        if (b == me) return 1;
        return (directory.profile(a)?.name ?? '').toLowerCase().compareTo(
          (directory.profile(b)?.name ?? '').toLowerCase(),
        );
      });
    final root = AppRoutes.navigatorKey.currentContext;

    return Container(
      constraints: BoxConstraints(maxHeight: screen.height * 0.7),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSheets.radius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: const BorderRadius.all(
                Radius.circular(AppSheets.radius),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: screen.width * 0.04),
            child: Column(
              children: [
                const SheetHandle(),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox(width: double.infinity, height: 48),
                    Text(
                      '${l10n.messagesGroupMembersTitle} · ${members.length}',
                      style: AppTextStyles.pageTitle(
                        context,
                      ).copyWith(fontSize: screen.height * 0.026),
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
                const SizedBox(height: 8),
              ],
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(16, 12, 16, screen.height * 0.03),
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                final uid = sorted[index];
                final profile = directory.profile(uid);
                final isMe = uid == me;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DecoratedBox(
                    decoration: BoxDecorations.whiteCard(context),
                    child: UserListTile(
                      uid: uid,
                      name: isMe
                          ? '${profile?.name ?? ''} (${l10n.capsulesYou})'
                          : profile?.name ?? '',
                      username: profile?.username ?? '',
                      screenWidth: screen.width,
                      onTap: isMe || root == null
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              friends.friendIds.contains(uid)
                                  ? AppRoutes.toFriendProfile(root, uid)
                                  : AppRoutes.toAddFriendProfile(root, uid);
                            },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A card to rename a group: the name, editable, and Save. Resolves to the
/// new name, or null when dismissed.
class GroupRenameCard extends StatefulWidget {
  const GroupRenameCard({super.key, required this.name});

  final String name;

  static Future<String?> show(BuildContext context, String name) =>
      showCenteredSheet<String>(context, GroupRenameCard(name: name));

  @override
  State<GroupRenameCard> createState() => _GroupRenameCardState();
}

class _GroupRenameCardState extends State<GroupRenameCard> {
  late final TextEditingController _name = TextEditingController(
    text: widget.name,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSheets.radius),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.messagesGroupRename,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSheets.radius),
            ),
            child: TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [
                LengthLimitingTextInputFormatter(Chat.maxGroupName),
              ],
              onSubmitted: (_) => _save(),
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                color: palette.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: l10n.messagesGroupName,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            button: true,
            child: AppPressable(
              child: GestureDetector(
                onTap: _save,
                child: Container(
                  width: 180,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen,
                    borderRadius: BorderRadius.circular(AppSheets.radius),
                  ),
                  child: Text(
                    l10n.messagesGroupSave,
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onAccent,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

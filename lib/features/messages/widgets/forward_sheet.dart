import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';
import '../../../shared/widgets/user/user_list_tile.dart';
import '../../../shared/widgets/user/user_round_avatar.dart';
import '../../friends/friends_store.dart';
import '../../users/user_directory.dart';
import '../chats_store.dart';
import 'group_avatar.dart';

/// Where a forwarded message goes: a friend or a group.
typedef ForwardTarget = ({String? friendUid, String? groupId, String name});

/// The user's groups, then their friends; tapping one picks it.
class ForwardSheet extends StatelessWidget {
  const ForwardSheet({super.key});

  static Future<ForwardTarget?> show(BuildContext context) =>
      showEdgeSheet<ForwardTarget>(context, (_) => const ForwardSheet());

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final palette = context.palette;
    final l10n = context.l10n;
    final directory = context.watch<UserDirectory>();
    final groups = context.watch<ChatsStore>().chats.where((c) => c.isGroup);
    final friends = [...context.watch<FriendsStore>().friendIds]
      ..sort(
        (a, b) => (directory.profile(a)?.name ?? '').toLowerCase().compareTo(
          (directory.profile(b)?.name ?? '').toLowerCase(),
        ),
      );
    final radius = UserRoundAvatar.listRadius(screen.width);

    Widget row(Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecorations.whiteCard(context),
        child: child,
      ),
    );

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
                      l10n.messagesForwardTo,
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 12, 16, screen.height * 0.03),
              children: [
                for (final g in groups)
                  row(
                    ListTile(
                      onTap: () => Navigator.of(context).pop<ForwardTarget>((
                        friendUid: null,
                        groupId: g.id,
                        name: g.name,
                      )),
                      leading: GroupAvatar(
                        groupId: g.id,
                        name: g.name,
                        radius: radius,
                      ),
                      title: Text(
                        g.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.listName(context),
                      ),
                    ),
                  ),
                for (final uid in friends)
                  row(
                    UserListTile(
                      uid: uid,
                      name: directory.profile(uid)?.name ?? '',
                      username: directory.profile(uid)?.username ?? '',
                      screenWidth: screen.width,
                      onTap: () => Navigator.of(context).pop<ForwardTarget>((
                        friendUid: uid,
                        groupId: null,
                        name: directory.profile(uid)?.name ?? '',
                      )),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

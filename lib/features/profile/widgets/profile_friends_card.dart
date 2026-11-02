import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/styles/box_decorations.dart';
import '../../../shared/widgets/options_menu.dart';
import '../../../shared/widgets/pin_mark.dart';
import '../../friends/pinned_friends_controller.dart';
import '../../friends/widgets/friend_stamp.dart';
import '../../friends/widgets/pin_friends_sheet.dart';
import '../../users/user_directory.dart';

/// The profile's friends: pinned ones first, then the ones the user chatted
/// with lately (F-56). A tap opens quick actions (write, send a capsule,
/// profile, pin); a long press pins or unpins.
class ProfileFriendsCard extends StatelessWidget {
  const ProfileFriendsCard({super.key});

  /// The stamps' width (the size of the old avatars).
  static const _stamp = 56.0;

  static Future<void> _quickActions(
    BuildContext context,
    PinnedFriendsController controller,
    String uid,
  ) async {
    final l10n = context.l10n;
    final name = context.read<UserDirectory>().profile(uid)?.name;
    final pinned = controller.isPinned(uid);
    final choice = await showCenteredSheet<_Quick>(
      context,
      OptionsMenu(
        children: [
          OptionsMenuTitle(name ?? l10n.commonUnknownUser),
          OptionsMenuItem(
            text: l10n.profileQuickMessage,
            onPressed: () => Navigator.of(context).pop(_Quick.message),
          ),
          const OptionsMenuDivider(),
          OptionsMenuItem(
            text: l10n.profileQuickCapsule,
            onPressed: () => Navigator.of(context).pop(_Quick.capsule),
          ),
          const OptionsMenuDivider(),
          OptionsMenuItem(
            text: l10n.profileViewProfile,
            onPressed: () => Navigator.of(context).pop(_Quick.profile),
          ),
          const OptionsMenuDivider(),
          OptionsMenuItem(
            text: pinned ? l10n.profileUnpin : l10n.profilePin,
            isLast: true,
            onPressed: () => Navigator.of(context).pop(_Quick.pin),
          ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _Quick.message:
        await AppRoutes.toChat(context, uid);
      case _Quick.capsule:
        await AppRoutes.toCamera(context, recipientId: uid);
      case _Quick.profile:
        await AppRoutes.toFriendProfile(context, uid);
      case _Quick.pin:
        await togglePinnedFriend(context, controller, uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PinnedFriendsController>();
    final palette = context.palette;
    final l10n = context.l10n;
    final count = controller.allFriends.length;
    return Container(
      width: double.infinity,
      decoration: BoxDecorations.whiteCard(context),
      padding: const EdgeInsets.fromLTRB(18, 6, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  count == 0
                      ? l10n.profileFriendsSection
                      : '${l10n.profileFriendsSection} · $count',
                  style: TextStyle(
                    fontFamily: kAppFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: palette.textSecondary,
                  ),
                ),
              ),
              if (count > 0) ...[
                IconButton(
                  tooltip: l10n.profileChoosePinned,
                  onPressed: () => PinFriendsSheet.open(context, controller),
                  icon: PinMark(color: palette.icon, size: 18),
                ),
                TextButton(
                  onPressed: () => AppRoutes.toMyFriends(context),
                  child: Text(
                    l10n.profileFriendsAll,
                    style: const TextStyle(
                      fontFamily: kAppFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandGreen,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (controller.isLoading)
            _Row(children: [for (var i = 0; i < 4; i++) const _Skeleton()])
          else if (count == 0)
            _NoFriends(onTap: () => AppRoutes.toAddFriends(context))
          else
            _Row(
              children: [
                for (final (i, uid) in controller.displayFriends.indexed)
                  _FriendChip(
                    key: ValueKey(uid),
                    uid: uid,
                    tilt: FriendStamp.tiltAt(i),
                    pinned: controller.isPinned(uid),
                    onTap: () => _quickActions(context, controller, uid),
                    onLongPress: () =>
                        togglePinnedFriend(context, controller, uid),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

enum _Quick { message, capsule, profile, pin }

class _Row extends StatelessWidget {
  const _Row({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 12, top: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final child in children) Expanded(child: child),
        // Fewer than five: they keep their size, on the left.
        for (var i = children.length; i < PinnedFriendsController.maxShown; i++)
          const Expanded(child: SizedBox.shrink()),
      ],
    ),
  );
}

class _FriendChip extends StatelessWidget {
  const _FriendChip({
    super.key,
    required this.uid,
    required this.tilt,
    required this.pinned,
    required this.onTap,
    required this.onLongPress,
  });

  final String uid;
  final double tilt;
  final bool pinned;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final name = context.select<UserDirectory, String>(
      (d) => d.profile(uid)?.name ?? '',
    );
    final first = name.trim().split(RegExp(r'\s+')).first;
    return Semantics(
      button: true,
      label: pinned ? '$name, ${context.l10n.messagesPinned}' : name,
      child: AppPressable(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: ExcludeSemantics(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    FriendStamp(
                      userId: uid,
                      size: ProfileFriendsCard._stamp,
                      tilt: tilt,
                    ),
                    if (pinned)
                      Positioned(
                        right: -6,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const PinMark(
                            color: AppColors.brandGreen,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: FriendStamp.heightFor(ProfileFriendsCard._stamp),
        child: Center(
          child: Container(
            width: ProfileFriendsCard._stamp,
            height: ProfileFriendsCard._stamp,
            decoration: BoxDecoration(
              color: context.palette.skeleton,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
      const SizedBox(height: 25),
    ],
  );
}

class _NoFriends extends StatelessWidget {
  const _NoFriends({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 70,
    child: Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.profileNoFriends,
                style: TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.profileNoFriendsAction,
                style: const TextStyle(
                  fontFamily: kAppFontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandGreen,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

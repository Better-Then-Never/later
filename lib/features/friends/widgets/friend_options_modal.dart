import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_sheets.dart';
import '../../../shared/widgets/options/options_section.dart';
import '../../../shared/widgets/pin_mark.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/user/verified_name.dart';
import '../../profile/share/sharing_service.dart';
import '../../settings/settings_store.dart';
import '../../users/user_directory.dart';
import '../friends_store.dart';
import '../pinned_friends_controller.dart';
import 'block_user.dart';
import 'friend_stamp.dart';
import 'pin_friends_sheet.dart';
import 'report_user.dart';

/// What a row of the friend's menu asks for; done after the sheet closed,
/// with the page's context.
enum _FriendMenu { pin, share, remove, block, report }

/// A friend's menu (Figma page 14, `7189:1113`): their stamp and name, then
/// Pin to my profile, Share their card, notifications about their capsules
/// (following), Remove friend, and Block and Report in red.
///
/// The app keeps no date for a friendship and has no per-person mute, so
/// "Friends since" and "Mute notifications" from the design are left out;
/// following is the app's switch for a friend's notifications.
class FriendOptionsModal extends StatefulWidget {
  final String friendUid;

  const FriendOptionsModal({super.key, required this.friendUid});

  /// Opens the menu. [leavePage]: removing the friend also leaves the page
  /// (their profile); false where the page lists all friends.
  static Future<void> show(
    BuildContext context,
    String friendUid, {
    bool leavePage = true,
  }) async {
    final choice = await showEdgeSheet<_FriendMenu>(
      context,
      (_) => FriendOptionsModal(friendUid: friendUid),
    );
    if (choice == null || !context.mounted) return;
    switch (choice) {
      case _FriendMenu.pin:
        final pins = PinnedFriendsController(
          friends: context.read<FriendsStore>(),
          settings: context.read<SettingsStore>(),
        );
        await togglePinnedFriend(context, pins, friendUid);
        pins.dispose();
      case _FriendMenu.share:
        await SharingService.shareUserProfile(
          context: context,
          userId: friendUid,
        );
      case _FriendMenu.remove:
        RemoveFriendConfirmModal.show(context, friendUid, leavePage: leavePage);
      case _FriendMenu.block:
        await confirmBlockUser(context, friendUid);
      case _FriendMenu.report:
        await reportUser(context, friendUid);
    }
  }

  @override
  State<FriendOptionsModal> createState() => _FriendOptionsModalState();
}

class _FriendOptionsModalState extends State<FriendOptionsModal> {
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    final isFollowing = await context.read<FriendsStore>().isFollowing(
      widget.friendUid,
    );
    if (mounted) {
      setState(() {
        _isFollowing = isFollowing;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    final store = context.read<FriendsStore>();
    final wasFollowing = _isFollowing;
    setState(() => _isLoading = true);

    final failure = wasFollowing
        ? await store.unfollow(widget.friendUid)
        : await store.follow(widget.friendUid);
    if (!mounted) return;

    setState(() {
      if (failure == null) _isFollowing = !wasFollowing;
      _isLoading = false;
    });
    if (failure != null) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.top,
      );
    } else {
      PopupNotificationService.showSuccess(
        context: context,
        message: wasFollowing
            ? context.l10n.friendsUnfollowed
            : context.l10n.friendsFollowed,
        position: NotificationPosition.top,
      );
    }
  }

  void _close(_FriendMenu choice) => Navigator.pop(context, choice);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    final uid = widget.friendUid;
    final profile = context.select<UserDirectory, ({String name, String user})>(
      (d) => (
        name: d.profile(uid)?.name ?? l10n.commonUnknownUser,
        user: d.profile(uid)?.username ?? l10n.commonUnknownUsername,
      ),
    );
    final first = profile.name.trim().split(RegExp(r'\s+')).first;
    final pinned = context.select<SettingsStore, bool>(
      (s) => s.pinnedFriends.contains(uid),
    );
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: SheetHandle.v2()),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    FriendStamp(userId: uid, size: 44),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VerifiedName(
                            uid: uid,
                            name: profile.name,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                          Text(
                            '@${profile.user}',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              color: palette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _MenuRow(
                leading: PinMark(color: palette.icon, size: 22),
                title: pinned
                    ? l10n.friendsUnpinFromProfile
                    : l10n.friendsPinToProfile,
                onTap: () => _close(_FriendMenu.pin),
              ),
              _MenuRow(
                leading: Image.asset(
                  AppIcons.shareBlack,
                  width: 24,
                  height: 24,
                  color: palette.icon,
                ),
                title: l10n.friendsShareTheirCard(first),
                onTap: () => _close(_FriendMenu.share),
              ),
              _MenuRow(
                leading: Icon(
                  _isFollowing
                      ? Icons.notifications_active
                      : Icons.notifications_outlined,
                  size: 24,
                  color: palette.icon,
                ),
                title: l10n.friendsFollowRow(first),
                onTap: _isLoading ? null : _toggleFollow,
                trailing: _isLoading
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          color: palette.icon,
                          strokeWidth: 2,
                        ),
                      )
                    : AppSwitch(
                        value: _isFollowing,
                        compact: true,
                        onChanged: (_) => _toggleFollow(),
                      ),
              ),
              _MenuRow(
                leading: Image.asset(
                  AppIcons.profileMyFriends,
                  width: 26,
                  height: 26,
                ),
                title: l10n.friendsRemoveFriend,
                onTap: () => _close(_FriendMenu.remove),
              ),
              _MenuRow(
                title: l10n.friendsBlock,
                danger: true,
                onTap: () => _close(_FriendMenu.block),
              ),
              _MenuRow(
                title: l10n.friendsReport,
                danger: true,
                last: true,
                onTap: () => _close(_FriendMenu.report),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row of the menu: an icon in a 28 dp slot (empty for the red rows,
/// so the words line up), the words, a hairline under it.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.title,
    required this.onTap,
    this.leading,
    this.trailing,
    this.danger = false,
    this.last = false,
  });

  final String title;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final bool danger;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          margin: const EdgeInsets.only(left: 20),
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            border: last
                ? null
                : Border(bottom: BorderSide(color: palette.divider)),
          ),
          child: Row(
            children: [
              SizedBox(width: 28, child: Center(child: leading)),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    height: 1.25,
                    color: danger ? AppColors.danger : palette.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class RemoveFriendConfirmModal extends StatefulWidget {
  final String friendUid;

  /// Leaves the page under this card too (the friend's profile).
  final bool leavePage;

  const RemoveFriendConfirmModal({
    super.key,
    required this.friendUid,
    this.leavePage = true,
  });

  static void show(
    BuildContext context,
    String friendUid, {
    bool leavePage = true,
  }) {
    showCenteredSheet<void>(
      context,
      RemoveFriendConfirmModal(friendUid: friendUid, leavePage: leavePage),
    );
  }

  @override
  State<RemoveFriendConfirmModal> createState() =>
      _RemoveFriendConfirmModalState();
}

class _RemoveFriendConfirmModalState extends State<RemoveFriendConfirmModal> {
  bool _isRemoving = false;

  /// Removes the friend, closes this sheet and leaves their profile page
  /// (it no longer applies). The navigator is captured before the await so
  /// both pops target the right routes (BUG-089).
  Future<void> _removeFriend() async {
    if (_isRemoving) return;
    setState(() => _isRemoving = true);

    final navigator = Navigator.of(context);
    final failure = await context.read<FriendsStore>().removeFriend(
      widget.friendUid,
    );
    if (!mounted) return;

    if (failure == null) {
      navigator.pop();
      if (widget.leavePage) await navigator.maybePop('friend_removed');
      return;
    }
    setState(() => _isRemoving = false);
    PopupNotificationService.showError(
      context: context,
      message: failure.message,
      position: NotificationPosition.bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.only(top: 12, bottom: 1, left: 12, right: 12),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            context.l10n.friendsRemoveConfirm,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: kAppFontFamily,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _ConfirmButton(
            text: _isRemoving
                ? context.l10n.friendsRemoving
                : context.l10n.friendsRemoveAction,
            onPressed: _isRemoving ? null : _removeFriend,
            backgroundColor: AppColors.danger,
            textColor: AppColors.onAccent,
            isLoading: _isRemoving,
          ),
          _CancelButton(
            onPressed: _isRemoving ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color textColor;
  final bool isLoading;

  const _ConfirmButton({
    required this.text,
    required this.onPressed,
    required this.backgroundColor,
    required this.textColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 45,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: kAppFontFamily,
          ),
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: textColor,
                  strokeWidth: 2,
                ),
              )
            : Text(text),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _CancelButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: context.palette.textSecondary,
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: kAppFontFamily,
        ),
        splashFactory: NoSplash.splashFactory,
        overlayColor: Colors.transparent,
      ),
      child: Text(context.l10n.commonCancel),
    );
  }
}

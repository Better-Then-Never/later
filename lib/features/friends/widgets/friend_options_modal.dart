import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/options_menu.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import 'block_user.dart';
import '../../profile/share/sharing_service.dart';
import '../friends_store.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import 'package:later/core/theme/app_text_styles.dart';

class FriendOptionsModal extends StatelessWidget {
  final String friendUid;

  const FriendOptionsModal({super.key, required this.friendUid});

  static void show(BuildContext context, String friendUid) {
    showCenteredSheet<void>(context, FriendOptionsModal(friendUid: friendUid));
  }

  @override
  Widget build(BuildContext context) {
    return OptionsMenu(
      children: [
        OptionsMenuItem(
          text: context.l10n.friendsManageFriendship,
          onPressed: () {
            Navigator.pop(context);
            ManageFriendshipModal.show(context, friendUid);
          },
          isFirst: true,
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: context.l10n.friendsChatSettings,
          onPressed: () {
            Navigator.pop(context);
            // TODO: Handle chat settings action
          },
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: context.l10n.friendsCapsulesSettings,
          onPressed: () {
            Navigator.pop(context);
            // TODO: Handle capsules settings action
          },
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: context.l10n.friendsShareProfileTo,
          onPressed: () {
            Navigator.pop(context);
            // Same share sheet as the share button of the profile page;
            // the page context outlives this sheet.
            final page = AppRoutes.navigatorKey.currentContext;
            if (page != null) {
              SharingService.shareUserProfile(context: page, userId: friendUid);
            }
          },
          isLast: true,
        ),
      ],
    );
  }
}

class ManageFriendshipModal extends StatefulWidget {
  final String friendUid;

  const ManageFriendshipModal({super.key, required this.friendUid});

  static void show(BuildContext context, String friendUid) {
    showCenteredSheet<void>(
      context,
      ManageFriendshipModal(friendUid: friendUid),
    );
  }

  @override
  State<ManageFriendshipModal> createState() => _ManageFriendshipModalState();
}

class _ManageFriendshipModalState extends State<ManageFriendshipModal> {
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
        position: NotificationPosition.bottom,
      );
    } else {
      PopupNotificationService.showSuccess(
        context: context,
        message: wasFollowing
            ? context.l10n.friendsUnfollowed
            : context.l10n.friendsFollowed,
        position: NotificationPosition.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OptionsMenu(
      children: [
        _ModalHeader(text: context.l10n.friendsManageFriendship),
        OptionsMenuDivider(color: context.palette.textPrimary, thickness: 1),
        _FollowButton(
          isFollowing: _isFollowing,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _toggleFollow,
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: context.l10n.friendsReport,
          onPressed: () {
            Navigator.pop(context);
            // TODO: Handle report action
          },
          textColor: AppColors.danger,
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: context.l10n.friendsBlock,
          onPressed: () {
            Navigator.pop(context);
            confirmBlockUser(context, widget.friendUid);
          },
          textColor: AppColors.danger,
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: context.l10n.friendsRemove,
          onPressed: () {
            Navigator.pop(context);
            RemoveFriendConfirmModal.show(context, widget.friendUid);
          },
          textColor: AppColors.materialRed,
          isLast: true,
        ),
      ],
    );
  }
}

class RemoveFriendConfirmModal extends StatefulWidget {
  final String friendUid;

  const RemoveFriendConfirmModal({super.key, required this.friendUid});

  static void show(BuildContext context, String friendUid) {
    showCenteredSheet<void>(
      context,
      RemoveFriendConfirmModal(friendUid: friendUid),
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
      await navigator.maybePop('friend_removed');
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

class _ModalHeader extends StatelessWidget {
  final String text;

  const _ModalHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 37,
      width: 264,
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Center(
          // Longer translations shrink to the card's width instead of
          // wrapping out of the 37 px row (English fits unchanged).
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                fontFamily: kAppFontFamily,
                color: context.palette.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _FollowButton({
    required this.isFollowing,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 37,
      width: 264,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: context.palette.textPrimary,
          backgroundColor: isFollowing
              ? context.palette.skeleton
              : Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: kAppFontFamily,
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: context.palette.icon,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isFollowing
                          ? Icons.notifications_active
                          : Icons.notifications_outlined,
                      size: 20,
                      color: context.palette.icon,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isFollowing
                          ? context.l10n.friendsFollowing
                          : context.l10n.friendsFollow,
                    ),
                  ],
                ),
        ),
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

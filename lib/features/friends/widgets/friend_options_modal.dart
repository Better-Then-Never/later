import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/options_menu.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import 'block_user.dart';
import '../../profile/share/sharing_service.dart';
import '../friends_store.dart';
import '../../../core/theme/app_colors.dart';

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
          text: 'Manage friendship',
          onPressed: () {
            Navigator.pop(context);
            ManageFriendshipModal.show(context, friendUid);
          },
          isFirst: true,
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: 'Chat settings',
          onPressed: () {
            Navigator.pop(context);
            // TODO: Handle chat settings action
          },
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: 'Capsules settings',
          onPressed: () {
            Navigator.pop(context);
            // TODO: Handle capsules settings action
          },
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: 'Share profile to ...',
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
            ? 'Unfollowed successfully'
            : 'Following! You\'ll get notifications about their capsules',
        position: NotificationPosition.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OptionsMenu(
      children: [
        const _ModalHeader(text: 'Manage friendship'),
        const OptionsMenuDivider(color: Colors.black, thickness: 1),
        _FollowButton(
          isFollowing: _isFollowing,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _toggleFollow,
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: 'Report',
          onPressed: () {
            Navigator.pop(context);
            // TODO: Handle report action
          },
          textColor: AppColors.danger,
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: 'Block',
          onPressed: () {
            Navigator.pop(context);
            confirmBlockUser(context, widget.friendUid);
          },
          textColor: AppColors.danger,
        ),
        const OptionsMenuDivider(),
        OptionsMenuItem(
          text: 'Remove from friends',
          onPressed: () {
            Navigator.pop(context);
            RemoveFriendConfirmModal.show(context, widget.friendUid);
          },
          textColor: Colors.red,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Are you sure you want to remove user from friends?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Irina',
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _ConfirmButton(
            text: _isRemoving ? 'Removing...' : 'Remove',
            onPressed: _isRemoving ? null : _removeFriend,
            backgroundColor: AppColors.danger,
            textColor: Colors.white,
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
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              fontFamily: 'Irina',
              color: Colors.black,
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
          foregroundColor: Colors.black,
          backgroundColor: isFollowing ? Colors.grey[300] : Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: 'Irina',
          ),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.black,
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
                      color: Colors.black,
                    ),
                    const SizedBox(width: 8),
                    Text(isFollowing ? 'Following' : 'Follow'),
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
            fontFamily: 'Irina',
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
        foregroundColor: const Color.fromARGB(255, 95, 95, 95),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'Irina',
        ),
        splashFactory: NoSplash.splashFactory,
        overlayColor: Colors.transparent,
      ),
      child: const Text('Cancel'),
    );
  }
}

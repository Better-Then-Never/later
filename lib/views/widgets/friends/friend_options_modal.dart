import 'package:flutter/material.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/popup_notification_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:provider/provider.dart';

class FriendOptionsModal extends StatelessWidget {
  final String friendUid;

  const FriendOptionsModal({super.key, required this.friendUid});

  static void show(BuildContext context, String friendUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: FriendOptionsModal(friendUid: friendUid),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ModalContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModalOption(
            text: 'Manage friendship',
            onPressed: () {
              Navigator.pop(context);
              ManageFriendshipModal.show(context, friendUid);
            },
            isFirst: true,
          ),
          _ModalDivider(),
          _ModalOption(
            text: 'Chat settings',
            onPressed: () {
              Navigator.pop(context);
              // TODO: Handle chat settings action
            },
          ),
          _ModalDivider(),
          _ModalOption(
            text: 'Capsules settings',
            onPressed: () {
              Navigator.pop(context);
              // TODO: Handle capsules settings action
            },
          ),
          _ModalDivider(),
          _ModalOption(
            text: 'Share profile to ...',
            onPressed: () {
              Navigator.pop(context);
              // TODO: Handle share profile action
            },
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class ManageFriendshipModal extends StatefulWidget {
  final String friendUid;

  const ManageFriendshipModal({super.key, required this.friendUid});

  static void show(BuildContext context, String friendUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: ManageFriendshipModal(friendUid: friendUid),
            ),
          ),
        );
      },
    );
  }

  @override
  State<ManageFriendshipModal> createState() => _ManageFriendshipModalState();
}

class _ManageFriendshipModalState extends State<ManageFriendshipModal> {
  bool _isFollowing = false;
  bool _isLoading = true;
  final UserFriendsService _friendsService = UserFriendsService();

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
  }

  Future<void> _checkFollowStatus() async {
    try {
      final userService = Provider.of<UserDataService>(context, listen: false);
      final currentUserUid = userService.currentLoggedInUid;
      
      final isFollowing = await _friendsService.isFollowing(
        currentUserUid,
        widget.friendUid,
      );

      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final userService = Provider.of<UserDataService>(context, listen: false);
      final currentUserUid = userService.currentLoggedInUid;

      setState(() {
        _isLoading = true;
      });

      if (_isFollowing) {
        await _friendsService.unfollowUser(currentUserUid, widget.friendUid);
        if (mounted) {
          PopupNotificationService.showSuccess(
            context: context,
            message: 'Unfollowed successfully',
            position: NotificationPosition.bottom,
          );
        }
      } else {
        await _friendsService.followUser(currentUserUid, widget.friendUid);
        if (mounted) {
          PopupNotificationService.showSuccess(
            context: context,
            message: 'Following! You\'ll get notifications about their capsules',
            position: NotificationPosition.bottom,
          );
        }
      }

      if (mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        PopupNotificationService.showError(
          context: context,
          message: 'Failed to ${_isFollowing ? 'unfollow' : 'follow'} user',
          position: NotificationPosition.bottom,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ModalContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModalHeader(text: 'Manage friendship'),
          _ModalDivider(color: Colors.black, thickness: 1),
          _FollowButton(
            isFollowing: _isFollowing,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _toggleFollow,
          ),
          _ModalDivider(),
          _ModalOption(
            text: 'Report',
            onPressed: () {
              Navigator.pop(context);
              // TODO: Handle report action
            },
            textColor: const Color.fromARGB(255, 253, 65, 64),
          ),
          _ModalDivider(),
          _ModalOption(
            text: 'Block',
            onPressed: () {
              Navigator.pop(context);
              // TODO: Handle block action
            },
            textColor: const Color.fromARGB(255, 253, 65, 64),
          ),
          _ModalDivider(),
          _ModalOption(
            text: 'Remove from friends',
            onPressed: () {
              Navigator.pop(context);
              RemoveFriendConfirmModal.show(context, widget.friendUid);
            },
            textColor: Colors.red,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class RemoveFriendConfirmModal extends StatefulWidget {
  final String friendUid;

  const RemoveFriendConfirmModal({super.key, required this.friendUid});

  static void show(BuildContext context, String friendUid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withAlpha(128),
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: RemoveFriendConfirmModal(friendUid: friendUid),
            ),
          ),
        );
      },
    );
  }

  @override
  State<RemoveFriendConfirmModal> createState() =>
      _RemoveFriendConfirmModalState();
}

class _RemoveFriendConfirmModalState extends State<RemoveFriendConfirmModal> {
  bool _isRemoving = false;
  final UserFriendsService _requestService = UserFriendsService();

  @override
  void dispose() {
    PopupNotificationService.hide();
    super.dispose();
  }

  Future<void> _removeFriend() async {
    if (_isRemoving) return;

    setState(() {
      _isRemoving = true;
    });

    try {
      final userService = Provider.of<UserDataService>(context, listen: false);
      final userFriendsService = Provider.of<UserFriendsService>(
        context,
        listen: false,
      );
      final currentUserUid = userService.currentLoggedInUid;

      await _requestService.removeFriend(currentUserUid, widget.friendUid);
      await userFriendsService.refreshFriends();

      if (mounted) {
        Navigator.of(context).pop();
        Navigator.of(context).pop('friend_removed');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRemoving = false;
        });

        PopupNotificationService.showError(
          context: context,
          message: 'Failed to remove friend',
          position: NotificationPosition.bottom,
        );
      }
    }
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
            backgroundColor: const Color.fromARGB(255, 253, 65, 64),
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

class _ModalContainer extends StatelessWidget {
  final Widget child;

  const _ModalContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: child,
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

class _ModalOption extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? textColor;
  final bool isFirst;
  final bool isLast;

  const _ModalOption({
    required this.text,
    required this.onPressed,
    this.textColor,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius? borderRadius;
    if (isFirst && isLast) {
      borderRadius = BorderRadius.circular(25);
    } else if (isFirst) {
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      );
    } else if (isLast) {
      borderRadius = const BorderRadius.only(
        bottomLeft: Radius.circular(25),
        bottomRight: Radius.circular(25),
      );
    }

    return SizedBox(
      height: 37,
      width: 264,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? Colors.black,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: 'Irina',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.zero,
          ),
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
        ),
        child: Center(child: Text(text)),
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
          backgroundColor: isFollowing 
              ? Colors.grey[300] 
              : Colors.transparent,
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            fontFamily: 'Irina',
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
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
                      isFollowing ? Icons.notifications_active : Icons.notifications_outlined,
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

class _ModalDivider extends StatelessWidget {
  final Color? color;
  final double thickness;

  const _ModalDivider({this.color, this.thickness = 2});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      height: thickness,
      color: color ?? const Color.fromARGB(255, 211, 211, 211),
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
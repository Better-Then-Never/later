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

class ManageFriendshipModal extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return _ModalContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModalHeader(text: 'Manage friendship'),
          _ModalDivider(color: Colors.black, thickness: 1),
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
              BlockFriendConfirmModal.show(context, friendUid);
            },
            textColor: const Color.fromARGB(255, 253, 65, 64),
          ),
          _ModalDivider(),
          _ModalOption(
            text: 'Remove from friends',
            onPressed: () {
              Navigator.pop(context);
              RemoveFriendConfirmModal.show(context, friendUid);
            },
            textColor: Colors.red,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class BlockFriendConfirmModal extends StatefulWidget {
  final String friendUid;

  const BlockFriendConfirmModal({super.key, required this.friendUid});

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
              child: BlockFriendConfirmModal(friendUid: friendUid),
            ),
          ),
        );
      },
    );
  }

  @override
  State<BlockFriendConfirmModal> createState() =>
      _BlockFriendConfirmModalState();
}

class _BlockFriendConfirmModalState extends State<BlockFriendConfirmModal> {
  bool _isBlocking = false;

  @override
  void dispose() {
    PopupNotificationService.hide();
    super.dispose();
  }

  Future<void> _blockUser() async {
    if (_isBlocking) return;

    setState(() {
      _isBlocking = true;
    });

    try {
      final userService = Provider.of<UserDataService>(context, listen: false);
      final userFriendsService = Provider.of<UserFriendsService>(
        context,
        listen: false,
      );
      final currentUserUid = userService.currentLoggedInUid;

      await userFriendsService.blockUser(currentUserUid, widget.friendUid);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBlocking = false;
        });

        PopupNotificationService.showError(
          context: context,
          message: 'Failed to block user',
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
            'Are you sure you want to block this user?',
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
            text: _isBlocking ? 'Blocking...' : 'Block',
            onPressed: _isBlocking ? null : _blockUser,
            backgroundColor: const Color.fromARGB(255, 253, 65, 64),
            textColor: Colors.white,
            isLoading: _isBlocking,
          ),
          _CancelButton(
            onPressed: _isBlocking ? null : () => Navigator.pop(context),
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

import 'package:flutter/material.dart';

class ChatOptionsModal extends StatelessWidget {
  final String chatId;
  final String friendUid;
  final VoidCallback? onSearch;

  const ChatOptionsModal({
    super.key,
    required this.chatId,
    required this.friendUid,
    this.onSearch,
  });

  static void show(
    BuildContext context, {
    required String chatId,
    required String friendUid,
    VoidCallback? onSearch,
  }) {
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
              child: ChatOptionsModal(
                chatId: chatId,
                friendUid: friendUid,
                onSearch: onSearch,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChatModalOption(
            text: 'Search',
            onPressed: () {
              Navigator.pop(context);
              onSearch?.call();
            },
            isFirst: true,
          ),
          const _ChatModalDivider(),
          _ChatModalOption(
            text: 'Clear history',
            onPressed: () {
              Navigator.pop(context);
              ClearHistoryConfirmModal.show(context, chatId: chatId);
            },
            textColor: const Color.fromARGB(255, 253, 65, 64),
          ),
          const _ChatModalDivider(),
          _ChatModalOption(
            text: 'Block user',
            onPressed: () {
              Navigator.pop(context);
              BlockUserConfirmModal.show(context, friendUid: friendUid);
            },
            textColor: const Color.fromARGB(255, 253, 65, 64),
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class ClearHistoryConfirmModal extends StatefulWidget {
  final String chatId;

  const ClearHistoryConfirmModal({super.key, required this.chatId});

  static void show(BuildContext context, {required String chatId}) {
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
              child: ClearHistoryConfirmModal(chatId: chatId),
            ),
          ),
        );
      },
    );
  }

  @override
  State<ClearHistoryConfirmModal> createState() =>
      _ClearHistoryConfirmModalState();
}

class _ClearHistoryConfirmModalState extends State<ClearHistoryConfirmModal> {
  bool _isClearing = false;

  Future<void> _clearHistory() async {
    if (_isClearing) return;

    setState(() {
      _isClearing = true;
    });

    try {
      // TODO: Implement clear history via ChatService
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to clear history'),
            backgroundColor: Colors.red,
          ),
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
            'Are you sure you want to clear chat history?',
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
            text: _isClearing ? 'Clearing...' : 'Clear',
            onPressed: _isClearing ? null : _clearHistory,
            backgroundColor: const Color.fromARGB(255, 253, 65, 64),
            textColor: Colors.white,
            isLoading: _isClearing,
          ),
          _CancelButton(
            onPressed: _isClearing ? null : () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class BlockUserConfirmModal extends StatefulWidget {
  final String friendUid;

  const BlockUserConfirmModal({super.key, required this.friendUid});

  static void show(BuildContext context, {required String friendUid}) {
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
              child: BlockUserConfirmModal(friendUid: friendUid),
            ),
          ),
        );
      },
    );
  }

  @override
  State<BlockUserConfirmModal> createState() => _BlockUserConfirmModalState();
}

class _BlockUserConfirmModalState extends State<BlockUserConfirmModal> {
  bool _isBlocking = false;

  Future<void> _blockUser() async {
    if (_isBlocking) return;

    setState(() {
      _isBlocking = true;
    });

    try {
      // TODO: Implement block user via UserFriendsService
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBlocking = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to block user'),
            backgroundColor: Colors.red,
          ),
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

class _ChatModalOption extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? textColor;
  final bool isFirst;
  final bool isLast;

  const _ChatModalOption({
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

class _ChatModalDivider extends StatelessWidget {
  const _ChatModalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 264,
      height: 2,
      color: const Color.fromARGB(255, 211, 211, 211),
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

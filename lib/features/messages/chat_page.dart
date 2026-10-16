import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_routes.dart';
import '../../core/assets/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/capsule.dart';
import '../../data/models/chat.dart';
import '../../data/repositories/repositories.dart';
import '../../shared/widgets/popup/popup_notification_service.dart';
import '../../shared/widgets/user/user_round_avatar.dart';
import '../friends/friends_store.dart';
import '../map/widgets/capsule_preview_card.dart';
import '../users/user_directory.dart';
import 'chat_controller.dart';
import 'chat_time.dart';
import 'chats_store.dart';
import 'widgets/chat_options_sheet.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';

/// A conversation with one friend (main's PrivateMessagePage).
class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required this.friendUid});

  final String friendUid;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ChatController(
        friendUid: friendUid,
        chats: context.read<ChatsStore>(),
        friends: context.read<FriendsStore>(),
      ),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _scroll = ScrollController();
  final _searchController = TextEditingController();
  bool _showScrollToBottom = false;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _nearBottom =>
      !_scroll.hasClients ||
      _scroll.position.maxScrollExtent - _scroll.position.pixels <= 100;

  void _onScroll() {
    final show = !_nearBottom;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(end);
      }
    });
  }

  /// Follows new messages when the user is at the bottom (or on first load).
  void _followNewMessages(int count) {
    if (count == _lastCount) return;
    final first = _lastCount == 0;
    _lastCount = count;
    if (first || _nearBottom) _scrollToBottom(animate: !first);
  }

  Future<bool> _send(String text) async {
    final failure = await context.read<ChatController>().send(text);
    if (!mounted) return false;
    if (failure != null) {
      PopupNotificationService.showError(
        context: context,
        message: failure.message,
        position: NotificationPosition.top,
      );
      return false;
    }
    _scrollToBottom();
    return true;
  }

  void _toggleSearch(ChatController controller) {
    _searchController.clear();
    controller.toggleSearch();
  }

  Future<void> _openCapsule(String capsuleId) async {
    final capsule = await context.read<CapsuleRepository>().getById(capsuleId);
    if (!mounted) return;
    if (capsule == null) {
      PopupNotificationService.showError(
        context: context,
        message: 'This capsule is no longer available',
        position: NotificationPosition.top,
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: CapsulePreviewCard(capsule: capsule),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    // Rebuilds when this user blocks or unblocks the friend.
    context.watch<FriendsStore>();
    final friendUid = controller.friendUid;
    final friendName = context.select<UserDirectory, String>(
      (d) => d.profile(friendUid)?.name ?? 'Chat',
    );
    final screen = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: Column(
        children: [
          _ChatHeader(
            friendUid: friendUid,
            friendName: friendName,
            onMenu: () => ChatOptionsSheet.show(context, controller),
          ),
          if (controller.isSearching)
            _SearchBar(
              controller: _searchController,
              onChanged: controller.search,
              onCancel: () => _toggleSearch(controller),
            ),
          Expanded(
            child: Stack(
              children: [
                _messages(controller, friendName, screen),
                if (_showScrollToBottom)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: _ScrollToBottomButton(onTap: _scrollToBottom),
                  ),
              ],
            ),
          ),
          if (controller.canSend)
            MessageInput(
              onSend: _send,
              onCapsuleTap: () => AppRoutes.toCamera(
                context,
                privacy: CapsulePrivacy.private,
                recipientId: friendUid,
              ),
            )
          else
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    controller.iBlockedThem
                        ? 'You blocked this user'
                        : "You can't send messages to this user",
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: kAppFontFamily,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _messages(ChatController controller, String friendName, Size screen) {
    if (!controller.isLoaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brandGreen),
      );
    }
    if (controller.hasError) {
      return const _Info(
        icon: Icons.error_outline,
        title: 'Failed to load messages',
      );
    }
    if (!controller.hasMessages) {
      return _Info(
        icon: Icons.chat_bubble_outline,
        title: 'No messages yet',
        subtitle: 'Say hello to $friendName!',
      );
    }

    final messages = controller.visibleMessages;
    if (!controller.isSearching) _followNewMessages(messages.length);
    final now = DateTime.now();
    DateTime dayOf(ChatMessage m) => m.sentAt ?? now;

    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: screen.width * 0.04,
        vertical: 16,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final showDay =
            index == 0 ||
            !ChatTime.isSameDay(dayOf(messages[index - 1]), dayOf(message));
        final lastOfGroup =
            index == messages.length - 1 ||
            messages[index + 1].senderId != message.senderId ||
            !ChatTime.isSameDay(dayOf(message), dayOf(messages[index + 1]));
        final capsuleId = message.capsuleId;

        return Column(
          key: ValueKey(message.id),
          children: [
            if (showDay) _DaySeparator(ChatTime.dayLabel(message.sentAt, now)),
            MessageBubble(
              message: message,
              isMine: controller.isMine(message),
              showTail: lastOfGroup,
              onCapsuleTap: message.isCapsule && capsuleId != null
                  ? () => _openCapsule(capsuleId)
                  : null,
            ),
          ],
        );
      },
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.friendUid,
    required this.friendName,
    required this.onMenu,
  });

  final String friendUid;
  final String friendName;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screen.width * 0.03,
        vertical: screen.height * 0.01,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              icon: Image.asset(
                AppIcons.goBack,
                height: screen.height * 0.05,
                width: screen.height * 0.05,
              ),
              onPressed: () => Navigator.of(context).maybePop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            SizedBox(width: screen.width * 0.04),
            UserRoundAvatar(userId: friendUid, radius: screen.height * 0.025),
            SizedBox(width: screen.width * 0.04),
            Expanded(
              child: Text(
                friendName,
                style: TextStyle(
                  fontSize: screen.height * 0.025,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Chat options',
              icon: Image.asset(
                AppIcons.messagesChatMenu,
                height: screen.height * 0.075,
                width: screen.height * 0.075,
              ),
              onPressed: onMenu,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onCancel,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: 8,
      ),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 15, fontFamily: kAppFontFamily),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                hintStyle: TextStyle(
                  fontSize: 15,
                  fontFamily: kAppFontFamily,
                  color: Colors.grey[400],
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[400],
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.pageBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onCancel,
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 15,
                fontFamily: kAppFontFamily,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySeparator extends StatelessWidget {
  const _DaySeparator(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
      ),
    );
  }
}

class _ScrollToBottomButton extends StatelessWidget {
  const _ScrollToBottomButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.brandGreen,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

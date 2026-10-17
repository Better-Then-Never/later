import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_routes.dart';
import '../../core/assets/app_assets.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/capsule.dart';
import '../../data/models/chat.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/push_messaging_service.dart';
import '../../shared/motion/app_motion_widgets.dart';
import '../../shared/widgets/buttons/default_icon_button.dart';
import '../../shared/widgets/buttons/go_back_button.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/default_empty_inbox_info.dart';
import '../../shared/widgets/default_search_bar.dart';
import '../../shared/widgets/options_menu.dart';
import '../../shared/widgets/popup/popup_notification_service.dart';
import '../../shared/widgets/user/user_round_avatar.dart';
import '../friends/friends_store.dart';
import '../capsules/social/capsule_detail_dialog.dart';
import '../settings/settings_store.dart';
import '../users/user_directory.dart';
import 'chat_controller.dart';
import 'chat_time.dart';
import 'chats_store.dart';
import 'widgets/chat_options_sheet.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';
import 'widgets/reply_bar.dart';

/// A conversation with one friend.
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
        readReceipts: () => context.read<SettingsStore>().privacy.readReceipts,
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
  /// The list is reversed: offset 0 is the newest message.
  final _scroll = ScrollController();
  final _searchController = TextEditingController();
  final _inputFocus = FocusNode();
  bool _showScrollToLatest = false;

  /// Messages already on screen: only messages that arrive later animate in.
  final Set<String> _shown = {};
  bool _firstBuild = true;

  /// Pushes of this chat are not shown while it is open; the chat under
  /// this one (if any) gets its turn back when this page closes.
  late final PushMessagingService _push;
  String? _previousActiveChat;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _push = context.read<PushMessagingService>();
    final chatId = context.read<ChatController>().chatId;
    _previousActiveChat = _push.activeChatId;
    _push.activeChatId = chatId;
    if (chatId != null) unawaited(_push.clearChat(chatId));
  }

  @override
  void dispose() {
    _push.activeChatId = _previousActiveChat;
    _scroll.dispose();
    _searchController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    final show = position.pixels > 300;
    if (show != _showScrollToLatest) {
      setState(() => _showScrollToLatest = show);
    }
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<ChatController>().loadOlder();
    }
  }

  void _scrollToLatest() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      0,
      duration: AppMotion.of(context, AppMotion.slow),
      curve: AppMotion.enter,
    );
  }

  void _send(String text) {
    final controller = context.read<ChatController>();
    unawaited(controller.send(text).then(_report));
    _scrollToLatest();
  }

  void _retry(String messageId) {
    unawaited(context.read<ChatController>().retry(messageId).then(_report));
  }

  /// Held message: copy it, or delete the user's own for both.
  Future<void> _showMessageMenu(ChatMessage message) async {
    // The keyboard must not come back when the menu closes.
    FocusManager.instance.primaryFocus?.unfocus();
    final controller = context.read<ChatController>();
    final l10n = context.l10n;
    final canDelete = controller.canDelete(message);
    final canReply = controller.canReply(message);
    unawaited(HapticFeedback.selectionClick());
    final action = await showCenteredSheet<_MessageAction>(
      context,
      Builder(
        builder: (sheet) => OptionsMenu(
          children: [
            if (canReply) ...[
              OptionsMenuItem(
                text: l10n.capsulesReply,
                isFirst: true,
                onPressed: () => Navigator.pop(sheet, _MessageAction.reply),
              ),
              const OptionsMenuDivider(),
            ],
            OptionsMenuItem(
              text: l10n.messagesCopy,
              isFirst: !canReply,
              isLast: !canDelete,
              onPressed: () => Navigator.pop(sheet, _MessageAction.copy),
            ),
            if (canDelete) ...[
              const OptionsMenuDivider(),
              OptionsMenuItem(
                text: l10n.commonDelete,
                textColor: AppColors.danger,
                isLast: true,
                onPressed: () => Navigator.pop(sheet, _MessageAction.delete),
              ),
            ],
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _MessageAction.reply:
        _reply(message);
      case _MessageAction.copy:
        await Clipboard.setData(ClipboardData(text: message.text));
        if (!mounted) return;
        PopupNotificationService.showSuccess(
          context: context,
          message: l10n.messagesCopied,
          position: NotificationPosition.bottom,
        );
      case _MessageAction.delete:
        // Never arrived: only this phone has it, nothing to confirm.
        if (message.delivery == MessageDelivery.failed) {
          unawaited(controller.deleteMessage(message).then(_report));
          return;
        }
        await ConfirmDialog.show(
          context: context,
          title: l10n.messagesDeleteConfirmTitle,
          confirmText: l10n.commonDelete,
          onConfirm: () =>
              unawaited(controller.deleteMessage(message).then(_report)),
        );
    }
  }

  /// The next message answers [message]; the keyboard opens for it.
  void _reply(ChatMessage message) {
    context.read<ChatController>().replyTo(message);
    _inputFocus.requestFocus();
  }

  void _report(Object? failure) {
    if (failure == null || !mounted) return;
    PopupNotificationService.showError(
      context: context,
      message: failure.toString(),
      position: NotificationPosition.top,
    );
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
        message: context.l10n.messagesCapsuleUnavailable,
        position: NotificationPosition.top,
      );
      return;
    }
    await CapsuleDetailDialog.show(context, capsule);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ChatController>();
    // Rebuilds when this user blocks or unblocks the friend.
    context.watch<FriendsStore>();
    final friendUid = controller.friendUid;
    final fallbackName = context.l10n.messagesChatFallbackTitle;
    final friendName = context.select<UserDirectory, String>(
      (d) => d.profile(friendUid)?.name ?? fallbackName,
    );

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Column(
        children: [
          _ChatHeader(
            friendUid: friendUid,
            friendName: friendName,
            onMenu: () => ChatOptionsSheet.show(context, controller),
          ),
          if (controller.isSearching)
            _SearchRow(
              controller: _searchController,
              onChanged: controller.search,
              onCancel: () => _toggleSearch(controller),
            ),
          Expanded(
            child: Stack(
              children: [
                AppFadeSwitcher(child: _body(controller, friendName)),
                Positioned(
                  right: 16,
                  bottom: 12,
                  child: AnimatedScale(
                    scale: _showScrollToLatest ? 1 : 0,
                    duration: AppMotion.of(context, AppMotion.standard),
                    curve: _showScrollToLatest
                        ? AppMotion.enter
                        : AppMotion.exit,
                    child: _ScrollToLatestButton(onTap: _scrollToLatest),
                  ),
                ),
              ],
            ),
          ),
          if (controller.canSend) ...[
            AnimatedSize(
              duration: AppMotion.of(context, AppMotion.standard),
              curve: AppMotion.emphasizedCurve,
              alignment: Alignment.bottomCenter,
              child: switch (controller.replyingTo) {
                final reply? => ReplyBar(
                  key: ValueKey(reply.id),
                  name: reply.senderId == controller.myUid
                      ? context.l10n.capsulesYou
                      : friendName,
                  text: reply.text,
                  onCancel: controller.cancelReply,
                ),
                null => const SizedBox(width: double.infinity),
              },
            ),
            MessageInput(
              onSend: _send,
              focusNode: _inputFocus,
              onCapsuleTap: () => AppRoutes.toCamera(
                context,
                privacy: CapsulePrivacy.private,
                recipientId: friendUid,
              ),
            ),
          ] else
            _BlockedNotice(iBlockedThem: controller.iBlockedThem),
        ],
      ),
    );
  }

  Widget _body(ChatController controller, String friendName) {
    if (!controller.isLoaded) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(color: AppColors.brandGreen),
      );
    }
    final l10n = context.l10n;
    if (controller.hasError) {
      return DefaultEmptyInboxInfo(
        key: const ValueKey('error'),
        message: l10n.messagesLoadError,
        subtitle: l10n.messagesCheckConnection,
        assetPath: AppIcons.navbarMessages,
        actionText: l10n.commonRetry,
        onAction: controller.reload,
      );
    }
    if (!controller.hasMessages) {
      return DefaultEmptyInboxInfo(
        key: const ValueKey('empty'),
        message: l10n.messagesEmptyTitle,
        subtitle: l10n.messagesEmptySubtitle(friendName),
        assetPath: AppIcons.navbarMessages,
      );
    }
    final messages = controller.visibleMessages;
    if (messages.isEmpty) {
      return DefaultEmptyInboxInfo(
        key: const ValueKey('no-match'),
        message: l10n.messagesNoMatchTitle,
        subtitle: l10n.messagesNothingMatches(controller.query),
        assetPath: AppIcons.profileFriendSearch,
      );
    }

    final now = DateTime.now();
    DateTime dayOf(ChatMessage m) => m.sentAt ?? now;
    final receipt = controller.isSearching ? null : controller.receipt;
    final showOlderSpinner = controller.isLoadingOlder;
    final count = messages.length + (showOlderSpinner ? 1 : 0);
    final animate = !_firstBuild;
    _firstBuild = false;

    return ListView.builder(
      key: const ValueKey('list'),
      controller: _scroll,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      itemCount: count,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brandGreen,
                ),
              ),
            ),
          );
        }
        // Reversed: index 0 is the newest message.
        final i = messages.length - 1 - index;
        final message = messages[i];
        final older = i > 0 ? messages[i - 1] : null;
        final newer = i < messages.length - 1 ? messages[i + 1] : null;
        final firstOfDay =
            older == null || !ChatTime.isSameDay(dayOf(older), dayOf(message));
        final lastOfGroup =
            newer == null ||
            newer.senderId != message.senderId ||
            !ChatTime.isSameDay(dayOf(message), dayOf(newer));
        final capsuleId = message.capsuleId;
        final failed = message.delivery == MessageDelivery.failed;
        final isNew = animate && !_shown.contains(message.id);
        _shown.add(message.id);

        return AppEnter(
          key: ValueKey(message.id),
          animate: isNew,
          child: Column(
            children: [
              if (firstOfDay)
                _DaySeparator(
                  ChatTime.dayLabel(message.sentAt, now, l10n: l10n),
                ),
              _SwipeToReply(
                enabled: controller.canReply(message),
                onReply: () => _reply(message),
                child: GestureDetector(
                  onTap: failed ? () => _retry(message.id) : null,
                  onLongPress: () => _showMessageMenu(message),
                  child: MessageBubble(
                    message: message,
                    isMine: controller.isMine(message),
                    showTail: lastOfGroup,
                    replyName: message.replyTo == null
                        ? null
                        : message.replyTo!.senderId == controller.myUid
                        ? l10n.capsulesYou
                        : friendName,
                    onCapsuleTap: message.isCapsule && capsuleId != null
                        ? () => _openCapsule(capsuleId)
                        : null,
                  ),
                ),
              ),
              if (index == 0 && receipt != null)
                _Receipt(status: receipt, onRetry: () => _retry(message.id)),
              SizedBox(height: lastOfGroup ? 10 : 3),
            ],
          ),
        );
      },
    );
  }
}

/// White header like every page: back, the friend's avatar and name, menu.
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
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadii.l),
          bottomRight: Radius.circular(AppRadii.l),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        screen.height * 0.04,
        16,
        screen.height * 0.012,
      ),
      child: Row(
        children: [
          GoBackButton(context: context),
          SizedBox(width: screen.width * 0.04),
          UserRoundAvatar(userId: friendUid, radius: screen.width * 0.06),
          SizedBox(width: screen.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  friendName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle(
                    context,
                  ).copyWith(fontSize: screen.height * 0.028),
                ),
                // Muted chats send no pushes; say so where it matters.
                if (context.select<ChatController, bool>((c) => c.isMuted))
                  Text(
                    context.l10n.messagesNotificationsMuted,
                    style: AppTextStyles.body.copyWith(
                      color: context.palette.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          DefaultIconButton(
            onTap: onMenu,
            assetPath: AppIcons.messagesChatMenu,
            semanticLabel: context.l10n.messagesChatOptions,
            size: screen.width * 0.12,
          ),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.04,
        12,
        screenWidth * 0.04,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: DefaultSearchBar(
              controller: controller,
              hintText: context.l10n.messagesSearchHint,
              color: context.palette.surface,
              onChanged: onChanged,
            ),
          ),
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: context.palette.textSecondary,
            ),
            child: Text(
              context.l10n.commonCancel,
              style: const TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: context.palette.surfaceMuted,
            borderRadius: AppRadii.lCircular,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: kAppFontFamily,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: context.palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Sending…", "Sent", "Read" or "Not sent · Tap to retry" under the user's
/// newest message.
class _Receipt extends StatelessWidget {
  const _Receipt({required this.status, required this.onRetry});

  final ReceiptStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final muted = context.palette.textMuted;
    final (text, color) = switch (status) {
      ReceiptStatus.sending => (l10n.messagesReceiptSending, muted),
      ReceiptStatus.sent => (l10n.messagesReceiptSent, muted),
      ReceiptStatus.read => (l10n.messagesReceiptRead, AppColors.brandGreen),
      ReceiptStatus.failed => (l10n.messagesReceiptFailed, AppColors.danger),
    };
    final label = Padding(
      padding: const EdgeInsets.only(top: 3, right: 4),
      child: AnimatedSwitcher(
        duration: AppMotion.of(context, AppMotion.fast),
        child: Text(
          text,
          key: ValueKey(status),
          style: TextStyle(
            fontFamily: kAppFontFamily,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
    return Align(
      alignment: Alignment.centerRight,
      child: status == ReceiptStatus.failed
          ? GestureDetector(onTap: onRetry, child: label)
          : label,
    );
  }
}

class _ScrollToLatestButton extends StatelessWidget {
  const _ScrollToLatestButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.messagesScrollToLatest,
      child: AppPressable(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.palette.surface,
              shape: BoxShape.circle,
              boxShadow: AppShadows.raised(context),
            ),
            // The app's back arrow, turned to point down.
            child: Transform.rotate(
              angle: -math.pi / 2,
              child: Image.asset(AppIcons.goBack),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlockedNotice extends StatelessWidget {
  const _BlockedNotice({required this.iBlockedThem});

  final bool iBlockedThem;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            iBlockedThem
                ? context.l10n.messagesBlockedByYou
                : context.l10n.messagesCantSend,
            style: TextStyle(
              fontSize: 14,
              fontFamily: kAppFontFamily,
              color: context.palette.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

enum _MessageAction { reply, copy, delete }

/// Drag a message to the right to answer it: it follows the finger, a light
/// tick says "far enough", and it springs back on release.
class _SwipeToReply extends StatefulWidget {
  const _SwipeToReply({
    required this.enabled,
    required this.onReply,
    required this.child,
  });

  final bool enabled;
  final VoidCallback onReply;
  final Widget child;

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  static const _threshold = 56.0;
  static const _max = 72.0;

  late final AnimationController _back = AnimationController(vsync: this)
    ..addListener(_onBack);
  double _dx = 0;
  double _releasedAt = 0;
  bool _armed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _back.duration = AppMotion.of(context, AppMotion.fast);
  }

  @override
  void dispose() {
    _back.dispose();
    super.dispose();
  }

  void _onBack() => setState(
    () => _dx = _releasedAt * (1 - AppMotion.exit.transform(_back.value)),
  );

  void _onUpdate(DragUpdateDetails details) {
    _back.stop();
    setState(() => _dx = (_dx + details.delta.dx).clamp(0, _max));
    final armed = _dx >= _threshold;
    if (armed && !_armed) unawaited(HapticFeedback.selectionClick());
    _armed = armed;
  }

  void _onEnd() {
    if (_armed) widget.onReply();
    _armed = false;
    _releasedAt = _dx;
    unawaited(_back.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return GestureDetector(
      onHorizontalDragUpdate: _onUpdate,
      onHorizontalDragEnd: (_) => _onEnd(),
      onHorizontalDragCancel: _onEnd,
      child: Transform.translate(offset: Offset(_dx, 0), child: widget.child),
    );
  }
}

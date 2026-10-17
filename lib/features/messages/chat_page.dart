import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_routes.dart';
import '../../core/assets/app_assets.dart';
import '../../core/errors/app_failure.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../core/logging/perf_marks.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/capsule.dart';
import '../../data/models/chat.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/push_messaging_service.dart';
import '../../data/services/voice_service.dart';
import '../../shared/motion/app_motion_widgets.dart';
import '../../shared/motion/reaction_burst.dart';
import '../../shared/widgets/buttons/default_icon_button.dart';
import '../../shared/widgets/buttons/go_back_button.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../../shared/widgets/default_empty_inbox_info.dart';
import '../../shared/widgets/default_search_bar.dart';
import '../../shared/widgets/app_sheets.dart';
import '../../shared/widgets/options_menu.dart';
import '../../shared/widgets/photo_viewer.dart';
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
import 'widgets/group_avatar.dart';
import 'widgets/message_bubble.dart';
import 'widgets/message_input.dart';
import 'widgets/photo_message.dart';
import 'widgets/photo_send_card.dart';
import 'widgets/typing_label.dart';
import 'widgets/voice_recorder_bar.dart';
import 'voice_player.dart';
import 'widgets/reply_bar.dart';

/// A conversation with one friend, or a group.
class ChatPage extends StatelessWidget {
  const ChatPage({super.key, required String this.friendUid}) : groupId = null;

  const ChatPage.group({super.key, required String this.groupId})
    : friendUid = null;

  final String? friendUid;
  final String? groupId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        final chats = context.read<ChatsStore>();
        final friends = context.read<FriendsStore>();
        bool readReceipts() =>
            context.read<SettingsStore>().privacy.readReceipts;
        final group = groupId;
        return group != null
            ? ChatController.group(
                groupId: group,
                chats: chats,
                friends: friends,
                readReceipts: readReceipts,
              )
            : ChatController(
                friendUid: friendUid!,
                chats: chats,
                friends: friends,
                readReceipts: readReceipts,
              );
      },
      child: ChangeNotifierProvider(
        // Playback stops when the chat closes.
        create: (context) => VoicePlayer(context.read<VoiceService>()),
        child: const _ChatView(),
      ),
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

  /// A voice message is being recorded (the bar replaces the field).
  bool _recording = false;

  /// Messages already on screen: only messages that arrive later animate in.
  final Set<String> _shown = {};

  /// Keys of the messages built so far, to scroll to one (a quote's tap).
  final Map<String, GlobalKey> _keys = {};

  /// The message briefly highlighted after jumping to it.
  String? _flash;
  Timer? _flashTimer;

  GlobalKey _keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);
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
    _flashTimer?.cancel();
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

  /// The photo button: gallery or camera, then the caption card, then the
  /// photo goes (shown at once, uploaded in the background).
  Future<void> _sendPhoto() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = context.l10n;
    final source = await showChoiceMenu<ImageSource>(
      context,
      title: l10n.messagesSendPhoto,
      choices: [
        MenuChoice(ImageSource.gallery, l10n.messagesChoosePhoto),
        MenuChoice(ImageSource.camera, l10n.messagesTakePhoto),
      ],
    );
    if (source == null || !mounted) return;
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        requestFullMetadata: false,
      );
    } catch (e) {
      AppLogger.warning('Picking a chat photo failed', error: e);
      if (mounted) _report(UnknownFailure(l10n.messagesPhotoUnreadable));
      return;
    }
    if (file == null || !mounted) return;
    final caption = await PhotoSendCard.show(context, file.path);
    if (caption == null || !mounted) return;
    final controller = context.read<ChatController>();
    unawaited(controller.sendPhoto(file.path, caption: caption).then(_report));
    _scrollToLatest();
  }

  Future<void> _openPhoto(ChatMessage message) async {
    final source = PhotoMessage.source(message);
    if (source == null) return;
    await PhotoViewer.show(
      context,
      source,
      heroTag: PhotoMessage.heroTag(message),
    );
  }

  /// The microphone: asks for it if needed, then the recording bar takes
  /// the field's place until the recording is sent or thrown away.
  Future<void> _startVoice() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final l10n = context.l10n;
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      PopupNotificationService.showError(
        context: context,
        message: l10n.messagesMicPermission,
        position: NotificationPosition.top,
      );
      return;
    }
    await context.read<VoicePlayer>().stop();
    if (mounted) setState(() => _recording = true);
  }

  void _sendVoice(String path, int durationMs, List<int> waveform) {
    final controller = context.read<ChatController>();
    unawaited(
      controller
          .sendVoice(path, durationMs: durationMs, waveform: waveform)
          .then(_report),
    );
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
    // Reacting needs the message on the server, like replying.
    final canReact = canReply;
    // A photo without a caption has no text to copy.
    final canCopy =
        message.type != ChatMessageType.image || message.caption.isNotEmpty;
    final items = [
      if (canReply) (l10n.capsulesReply, _MessageAction.reply, null),
      if (canCopy) (l10n.messagesCopy, _MessageAction.copy, null),
      if (canDelete)
        (l10n.commonDelete, _MessageAction.delete, AppColors.danger),
    ];
    if (items.isEmpty && !canReact) return;
    final mine = message.reactions[controller.myUid];
    unawaited(HapticFeedback.selectionClick());
    // A _MessageAction, or the ReactionType tapped in the top row.
    final action = await showCenteredSheet<Object>(
      context,
      Builder(
        builder: (sheet) => OptionsMenu(
          children: [
            if (canReact)
              _ReactionPicker(
                selected: mine,
                onPick: (type) => Navigator.pop(sheet, type),
              ),
            for (final (i, (text, action, color)) in items.indexed) ...[
              if (i > 0 || canReact) const OptionsMenuDivider(),
              OptionsMenuItem(
                text: text,
                textColor: color,
                isFirst: i == 0 && !canReact,
                isLast: i == items.length - 1,
                onPressed: () => Navigator.pop(sheet, action),
              ),
            ],
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action is ReactionType) {
      unawaited(controller.react(message, action).then(_report));
      return;
    }
    switch (action as _MessageAction) {
      case _MessageAction.reply:
        _reply(message);
      case _MessageAction.copy:
        await Clipboard.setData(
          ClipboardData(
            text: message.type == ChatMessageType.image
                ? message.caption
                : message.text,
          ),
        );
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

  /// Scrolls to the answered message [id] and lights it up for a moment.
  /// It may not be built yet (the list is lazy): first an estimate, then
  /// the exact position. Older than the loaded page or deleted: nothing.
  Future<void> _showQuoted(String id) async {
    final messages = context.read<ChatController>().visibleMessages;
    final duration = AppMotion.of(context, AppMotion.slow);
    final i = messages.indexWhere((m) => m.id == id);
    if (i < 0) return;
    for (var attempt = 0; attempt < 3; attempt++) {
      final target = _keys[id]?.currentContext;
      if (target != null && target.mounted) {
        await Scrollable.ensureVisible(
          target,
          alignment: 0.4,
          duration: duration,
          curve: AppMotion.standardCurve,
        );
        break;
      }
      if (!_scroll.hasClients) return;
      // Reversed list: offset 0 is the newest message.
      final fromNewest = messages.length - 1 - i;
      _scroll.jumpTo(
        _scroll.position.maxScrollExtent * fromNewest / messages.length,
      );
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    if (!mounted) return;
    setState(() => _flash = id);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _flash = null);
    });
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
    // Names of the friend, or of everyone writing in the group.
    final directory = context.watch<UserDirectory>();
    final l10n = context.l10n;
    final fallbackName = l10n.messagesChatFallbackTitle;
    String nameOf(String uid) => directory.profile(uid)?.name ?? fallbackName;
    final friendUid = controller.friendUid;
    final groupId = controller.groupId;
    final title = friendUid != null
        ? nameOf(friendUid)
        : controller.chat?.name ?? fallbackName;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Column(
        children: [
          _ChatHeader(
            avatar: (radius) => groupId != null
                ? GroupAvatar(groupId: groupId, name: title, radius: radius)
                : UserRoundAvatar(userId: friendUid!, radius: radius),
            title: title,
            subtitle: _subtitle(controller, nameOf),
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
                AppFadeSwitcher(child: _body(controller, nameOf, title)),
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
                      ? l10n.capsulesYou
                      : nameOf(reply.senderId),
                  text: reply.text,
                  onCancel: controller.cancelReply,
                ),
                null => const SizedBox(width: double.infinity),
              },
            ),
            AnimatedSwitcher(
              duration: AppMotion.of(context, AppMotion.standard),
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.exit,
              child: _recording
                  ? VoiceRecorderBar(
                      key: const ValueKey('recording'),
                      voice: context.read<VoiceService>(),
                      onSend: _sendVoice,
                      onDone: () {
                        if (mounted) setState(() => _recording = false);
                      },
                    )
                  : MessageInput(
                      key: const ValueKey('input'),
                      onSend: _send,
                      onVoiceTap:
                          controller.canSendVoice && VoiceService.isSupported
                          ? _startVoice
                          : null,
                      onPhotoTap: controller.canSendPhotos ? _sendPhoto : null,
                      onChanged: controller.onInputChanged,
                      focusNode: _inputFocus,
                      onCapsuleTap: friendUid == null
                          ? null
                          : () => AppRoutes.toCamera(
                              context,
                              privacy: CapsulePrivacy.private,
                              recipientId: friendUid,
                            ),
                    ),
            ),
          ] else if (controller.isGroup)
            const _GroupLeftNotice()
          else
            _BlockedNotice(iBlockedThem: controller.iBlockedThem),
        ],
      ),
    );
  }

  /// Under the name: who is typing; else, in a group, how many are in it;
  /// else, for a muted chat, that it sends no pushes.
  Widget? _subtitle(ChatController controller, String Function(String) nameOf) {
    final l10n = context.l10n;
    final typing = controller.typingPeople;
    if (typing.isNotEmpty) {
      return TypingLabel(
        text: !controller.isGroup
            ? l10n.messagesTyping
            : typing.length == 1
            ? l10n.messagesTypingName(nameOf(typing.first))
            : l10n.messagesTypingMany(typing.length),
      );
    }
    final secondary = AppTextStyles.body.copyWith(
      color: context.palette.textSecondary,
    );
    if (controller.isGroup) {
      return Text(
        l10n.messagesGroupMembers(controller.chat?.members.length ?? 1),
        style: secondary,
      );
    }
    if (controller.isMuted) {
      return Text(l10n.messagesNotificationsMuted, style: secondary);
    }
    return null;
  }

  Widget _body(
    ChatController controller,
    String Function(String) nameOf,
    String title,
  ) {
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
        subtitle: controller.isGroup
            ? l10n.messagesGroupHello
            : l10n.messagesEmptySubtitle(title),
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
    if (_firstBuild) PerfMarks.nextFrame('chat.messagesShown');
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
        // In a group, who wrote: over the first of their messages in a row.
        final senderName =
            controller.isGroup &&
                !controller.isMine(message) &&
                (firstOfDay || older.senderId != message.senderId)
            ? nameOf(message.senderId)
            : null;
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
              AnimatedContainer(
                key: _keyFor(message.id),
                duration: AppMotion.of(context, AppMotion.slow),
                decoration: BoxDecoration(
                  // Fades from the same colour, never through grey.
                  color: _flash == message.id
                      ? context.palette.selectedHighlight
                      : context.palette.selectedHighlight.withAlpha(0),
                  borderRadius: BorderRadius.circular(AppRadii.m),
                ),
                child: Column(
                  crossAxisAlignment: controller.isMine(message)
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
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
                          senderName: senderName,
                          replyName: message.replyTo == null
                              ? null
                              : message.replyTo!.senderId == controller.myUid
                              ? l10n.capsulesYou
                              : nameOf(message.replyTo!.senderId),
                          onQuoteTap: message.replyTo == null
                              ? null
                              : () => _showQuoted(message.replyTo!.id),
                          onCapsuleTap: message.isCapsule && capsuleId != null
                              ? () => _openCapsule(capsuleId)
                              : null,
                          onPhotoTap: message.isPhoto && !failed
                              ? () => _openPhoto(message)
                              : null,
                        ),
                      ),
                    ),
                    if (message.reactions.isNotEmpty)
                      _ReactionsPill(
                        reactions: message.reactions,
                        myUid: controller.myUid,
                        // Tapping takes the user's own reaction back.
                        onTap: () {
                          final mine = message.reactions[controller.myUid];
                          if (mine == null) return;
                          unawaited(
                            controller.react(message, mine).then(_report),
                          );
                        },
                      ),
                  ],
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

/// White header like every page: back, the friend's avatar and name (or
/// the group's), a line under the name (typing, members, muted), menu.
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.avatar,
    required this.title,
    required this.subtitle,
    required this.onMenu,
  });

  final Widget Function(double radius) avatar;
  final String title;
  final Widget? subtitle;
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
          avatar(screen.width * 0.06),
          SizedBox(width: screen.width * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.pageTitle(
                    context,
                  ).copyWith(fontSize: screen.height * 0.028),
                ),
                AnimatedSize(
                  duration: AppMotion.of(context, AppMotion.standard),
                  curve: AppMotion.standardCurve,
                  alignment: Alignment.topLeft,
                  child: subtitle ?? const SizedBox(width: double.infinity),
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

/// Instead of the message field once the user is no longer in the group.
class _GroupLeftNotice extends StatelessWidget {
  const _GroupLeftNotice();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
        child: Text(
          context.l10n.messagesGroupLeft,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: context.palette.textSecondary,
          ),
        ),
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

/// The six reactions in a row at the top of the message menu; the user's
/// current one is ringed in green.
class _ReactionPicker extends StatelessWidget {
  const _ReactionPicker({required this.selected, required this.onPick});

  final ReactionType? selected;
  final ValueChanged<ReactionType> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSheets.cardWidth,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final type in ReactionType.values)
              Semantics(
                button: true,
                selected: selected == type,
                label: context.l10n.capsulesReactWith(type.emoji),
                child: AppPressable(
                  child: GestureDetector(
                    onTap: () => onPick(type),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected == type
                            ? AppColors.brandGreen.withValues(alpha: 0.18)
                            : null,
                        border: Border.all(
                          color: selected == type
                              ? AppColors.brandGreen
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        type.emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Under a message: the reactions on it (one emoji each, or "❤️ 2" when both
/// chose the same), ringed in green when one is the user's.
class _ReactionsPill extends StatelessWidget {
  const _ReactionsPill({
    required this.reactions,
    required this.myUid,
    required this.onTap,
  });

  final Map<String, ReactionType> reactions;
  final String? myUid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final counts = <ReactionType, int>{};
    for (final type in reactions.values) {
      counts[type] = (counts[type] ?? 0) + 1;
    }
    final mine = reactions.containsKey(myUid);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      // A 44 dp tall target around the 24 dp pill (docs/feel/FEEL_QA.md).
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 3, 6, 17),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadii.lCircular,
            border: Border.all(
              color: mine ? AppColors.brandGreen : palette.divider,
              width: 1.2,
            ),
          ),
          // Pops when the user's own reaction arrives.
          child: ReactionBurst(
            active: mine,
            child: Text(
              [
                for (final e in counts.entries)
                  e.value > 1 ? '${e.key.emoji} ${e.value}' : e.key.emoji,
              ].join(' '),
              style: TextStyle(
                fontFamily: kAppFontFamily,
                fontSize: 14,
                color: palette.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/shell/navbar_widget.dart';
import '../../app/router/app_routes.dart';
import '../../core/assets/app_assets.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/models/chat.dart';
import '../../shared/motion/app_motion_widgets.dart';
import '../../shared/styles/box_decorations.dart';
import '../../shared/widgets/buttons/default_icon_button.dart';
import '../../shared/widgets/default_empty_inbox_info.dart';
import '../../shared/widgets/default_search_bar.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/popup/popup_notification_service.dart';
import '../../shared/widgets/user/user_round_avatar.dart';
import '../../shared/widgets/user/user_row_skeleton.dart';
import '../settings/settings_store.dart';
import '../users/user_directory.dart';
import 'chats_store.dart';
import 'widgets/chat_list_item.dart';
import 'widgets/group_avatar.dart';
import 'widgets/new_chat_sheet.dart';

/// The "Messages" tab: the user's chats, most recent first, with search.
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: Column(
        children: [
          PageHeader(
            mainText: context.l10n.messagesTitle,
            leadingButton: DefaultIconButton(
              onTap: () => NewChatSheet.show(context),
              assetPath: AppIcons.messagesNew,
              semanticLabel: context.l10n.messagesNewChatTitle,
            ),
            searchBar: DefaultSearchBar(
              controller: _searchController,
              hintText: context.l10n.messagesFindChatsHint,
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
          Expanded(child: _ChatList(query: _query)),
        ],
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  const _ChatList({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ChatsStore>();
    final directory = context.watch<UserDirectory>();
    final me = store.uid ?? '';
    final l10n = context.l10n;

    final Widget body;
    if (!store.isLoaded) {
      body = const _Skeleton(key: ValueKey('loading'));
    } else if (store.hasError) {
      body = DefaultEmptyInboxInfo(
        key: const ValueKey('error'),
        message: l10n.messagesChatsLoadError,
        subtitle: l10n.messagesCheckConnection,
        assetPath: AppIcons.navbarMessages,
        actionText: l10n.commonRetry,
        onAction: store.retry,
      );
    } else if (store.chats.isEmpty) {
      body = DefaultEmptyInboxInfo(
        key: const ValueKey('empty'),
        message: l10n.messagesNoChatsTitle,
        subtitle: l10n.messagesNoChatsSubtitle,
        assetPath: AppIcons.navbarMessages,
      );
    } else {
      bool matches(Chat chat) {
        if (query.isEmpty) return true;
        if (chat.isGroup) {
          return chat.name.toLowerCase().contains(query) ||
              chat.lastMessage.toLowerCase().contains(query);
        }
        final friend = directory.profile(chat.otherThan(me));
        return chat.lastMessage.toLowerCase().contains(query) ||
            (friend?.name.toLowerCase().contains(query) ?? false) ||
            (friend?.username.toLowerCase().contains(query) ?? false);
      }

      final chats = store.chats.where(matches).toList();
      body = chats.isEmpty
          ? DefaultEmptyInboxInfo(
              key: const ValueKey('no-match'),
              message: l10n.messagesNoChatsFound,
              subtitle: l10n.messagesNothingMatches(query),
              assetPath: AppIcons.profileFriendSearch,
              // The chat search reaches everyone (F-57).
              actionText: l10n.messagesFindPeople(query),
              onAction: () => AppRoutes.toAddFriends(context, query: query),
            )
          : ListView.separated(
              key: const ValueKey('list'),
              // Clear of the floating navbar, whatever the phone's bottom
              // inset (120 dp hid the last chat on 3-button navigation).
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                NavbarWidget.coveredHeight(context) + 16,
              ),
              itemCount: chats.length + (query.isEmpty ? 0 : 1),
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                // After the chats that match: everyone else (F-57).
                if (index == chats.length) return _FindPeople(query: query);
                final chat = chats[index];
                final mine = chat.lastSenderId == me;
                // A photo without a caption, or a voice message, says
                // what it is.
                final last = switch (chat.lastMessage) {
                  ChatMessage.photoSign =>
                    '${ChatMessage.photoSign} ${l10n.messagesPhoto}',
                  ChatMessage.voiceSign =>
                    '${ChatMessage.voiceSign} ${l10n.messagesVoice}',
                  final text => text,
                };
                if (chat.isGroup) {
                  final sender = chat.lastSenderId;
                  return _SwipeActions(
                    key: ValueKey('row-${chat.id}'),
                    chatId: chat.id,
                    child: ChatListItem(
                      key: ValueKey(chat.id),
                      friendUid: '',
                      avatar: GroupAvatar(
                        groupId: chat.id,
                        name: chat.name,
                        radius: UserRoundAvatar.listRadius(
                          MediaQuery.sizeOf(context).width,
                        ),
                      ),
                      name: chat.name,
                      semanticsLabel: l10n.messagesOpenGroup(chat.name),
                      // "You: …", "Anna: …", or how many are in it.
                      preview: !chat.hasMessages
                          ? l10n.messagesGroupMembers(chat.members.length)
                          : mine
                          ? l10n.messagesYouPrefix(last)
                          : sender == null
                          ? last
                          : '${directory.profile(sender)?.name ?? ''}: $last',
                      timestamp: chat.lastUpdated,
                      unread: chat.unreadFor(me),
                      muted: store.isMuted(chat.id),
                      pinned: store.isPinned(chat.id),
                      onTap: () => AppRoutes.toGroupChat(context, chat.id),
                    ),
                  );
                }
                final friendUid = chat.otherThan(me);
                return _SwipeActions(
                  key: ValueKey('row-${chat.id}'),
                  chatId: chat.id,
                  child: ChatListItem(
                    key: ValueKey(chat.id),
                    friendUid: friendUid,
                    name: directory.profile(friendUid)?.name ?? '',
                    preview: mine ? l10n.messagesYouPrefix(last) : last,
                    timestamp: chat.lastUpdated,
                    unread: chat.unreadFor(me),
                    muted: store.isMuted(chat.id),
                    pinned: store.isPinned(chat.id),
                    onTap: friendUid.isEmpty
                        ? () {}
                        : () => AppRoutes.toChat(context, friendUid),
                  ),
                );
              },
            );
    }
    return AppFadeSwitcher(child: body);
  }
}

/// "Find people: “anna”" under the chats a search found: the same text on
/// Add friends, by name and username.
class _FindPeople extends StatelessWidget {
  const _FindPeople({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton.icon(
      onPressed: () => AppRoutes.toAddFriends(context, query: query),
      icon: Image.asset(AppIcons.profileFriendSearch, width: 24),
      label: Text(
        context.l10n.messagesFindPeople(query),
        style: const TextStyle(
          fontFamily: kAppFontFamily,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.brandGreen,
        ),
      ),
    ),
  );
}

/// A chat row that swipes: to the right it is pinned or unpinned, to the
/// left muted or unmuted; it springs back either way. (The same actions are
/// in the chat's menu, for screen readers.)
class _SwipeActions extends StatelessWidget {
  const _SwipeActions({super.key, required this.chatId, required this.child});

  final String chatId;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final pinned = context.select<SettingsStore, bool>(
      (s) => s.isPinned(chatId),
    );
    final muted = context.select<SettingsStore, bool>((s) => s.isMuted(chatId));
    Widget label(String text, Color color, Alignment alignment) => Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadii.l),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: AppColors.onAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    return Dismissible(
      key: ValueKey('swipe-$chatId'),
      background: label(
        pinned ? l10n.messagesUnpin : l10n.messagesPin,
        AppColors.brandGreen,
        Alignment.centerLeft,
      ),
      secondaryBackground: label(
        muted ? l10n.messagesMenuUnmute : l10n.messagesMenuMute,
        palette.iconMuted,
        Alignment.centerRight,
      ),
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      confirmDismiss: (direction) async {
        unawaited(HapticFeedback.selectionClick());
        final settings = context.read<SettingsStore>();
        final failure = direction == DismissDirection.startToEnd
            ? await settings.setChatPinned(chatId, pinned: !pinned)
            : await settings.setChatMuted(chatId, muted: !muted);
        if (failure != null && context.mounted) {
          PopupNotificationService.showError(
            context: context,
            message: failure.message,
            position: NotificationPosition.top,
          );
        }
        return false;
      },
      child: child,
    );
  }
}

/// Grey rows in white cards while the chats load.
class _Skeleton extends StatelessWidget {
  const _Skeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => DecoratedBox(
        decoration: BoxDecorations.whiteCard(context),
        child: UserRowSkeleton(screenWidth: screenWidth),
      ),
    );
  }
}

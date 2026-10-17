import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_routes.dart';
import '../../core/assets/app_assets.dart';
import '../../core/l10n/l10n.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/chat.dart';
import '../../shared/motion/app_motion_widgets.dart';
import '../../shared/styles/box_decorations.dart';
import '../../shared/widgets/buttons/default_icon_button.dart';
import '../../shared/widgets/default_empty_inbox_info.dart';
import '../../shared/widgets/default_search_bar.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/user/user_row_skeleton.dart';
import '../users/user_directory.dart';
import 'chats_store.dart';
import 'widgets/chat_list_item.dart';
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
            )
          : ListView.separated(
              key: const ValueKey('list'),
              // Clear of the floating navbar.
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              itemCount: chats.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final chat = chats[index];
                final friendUid = chat.otherThan(me);
                final mine = chat.lastSenderId == me;
                return ChatListItem(
                  key: ValueKey(chat.id),
                  friendUid: friendUid,
                  name: directory.profile(friendUid)?.name ?? '',
                  preview: mine
                      ? l10n.messagesYouPrefix(chat.lastMessage)
                      : chat.lastMessage,
                  timestamp: chat.lastUpdated,
                  unread: chat.unreadFor(me),
                  muted: store.isMuted(chat.id),
                  onTap: friendUid.isEmpty
                      ? () {}
                      : () => AppRoutes.toChat(context, friendUid),
                );
              },
            );
    }
    return AppFadeSwitcher(child: body);
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/repositories/repositories.dart';
import '../../../data/services/contacts_service.dart';
import '../../../shared/motion/app_motion_widgets.dart';
import '../../../shared/widgets/app_segmented_tabs.dart';
import '../../../shared/widgets/default_search_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/popup/popup_notification_service.dart';
import '../../../shared/widgets/user/user_background_image.dart';
import '../../../shared/widgets/user/user_stamp.dart';
import '../../../shared/widgets/v2/card_v2.dart';
import '../../users/user_directory.dart';
import '../friend_actions.dart';
import '../friend_suggestions_controller.dart';
import '../friends_store.dart';
import '../widgets/add_friends/from_contacts.dart';
import '../widgets/add_friends/suggested_friends_list.dart';
import '../widgets/friend_stamp.dart';
import '../widgets/requests/friend_requests_received_row.dart';
import '../widgets/requests/friend_requests_sent_row.dart';

/// Add friends (Figma page 14, `7191:906`): search by name or username,
/// share your Later card or scan a friend's, then the requests you got
/// (and sent) or the people you may know.
class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key, this.query = ''});

  /// Searched right away (from the chats' "Find people").
  final String query;

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  late final _searchController = TextEditingController(text: widget.query);
  late final FriendSuggestionsController _suggestions;
  late bool _searching = widget.query.trim().isNotEmpty;

  /// The chosen tab; until the user picks one, Suggested, or Requests
  /// once there are any (and it stays there while they are answered).
  int? _tab;

  @override
  void initState() {
    super.initState();
    _suggestions = FriendSuggestionsController(
      users: context.read<UserRepository>(),
      directory: context.read<UserDirectory>(),
      friends: context.read<FriendsStore>(),
    );
    _searchController.addListener(() {
      _suggestions.search(_searchController.text);
      final searching = _searchController.text.trim().isNotEmpty;
      if (searching != _searching) setState(() => _searching = searching);
    });
    if (widget.query.isNotEmpty) _suggestions.search(widget.query);
  }

  @override
  void dispose() {
    PopupNotificationService.hide();
    _searchController.dispose();
    _suggestions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = context.watch<FriendsStore>();
    // Actions use the page context: rows disappear on success (BUG-084).
    final actions = FriendActions(
      context,
      position: NotificationPosition.bottom,
    );
    if (_tab == null && store.incomingCount > 0) _tab = 0;
    final tab = _tab ?? 1;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Column(
        children: [
          PageHeaderV2(
            title: l10n.friendsAddTitle,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.commonBack,
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                24 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [
                DefaultSearchBar(
                  controller: _searchController,
                  hintText: l10n.friendsSearchPeopleHint,
                ),
                if (_searching)
                  SuggestedFriendsList(
                    controller: _suggestions,
                    actions: actions,
                    label: l10n.friendsSearchResults,
                  )
                else ...[
                  const SizedBox(height: 4),
                  const _Tiles(),
                  const SizedBox(height: 12),
                  AppSegmentedTabs(
                    labels: [
                      l10n.friendsRequestsTab(store.incomingCount),
                      l10n.friendsSuggestedTab,
                    ],
                    selected: tab,
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                  const SizedBox(height: 8),
                  if (tab == 0)
                    _Requests(actions: actions)
                  else ...[
                    if (FeatureFlags.contactSuggestions &&
                        ContactsService.isSupported)
                      const FromContactsButton(),
                    SuggestedFriendsList(
                      controller: _suggestions,
                      actions: actions,
                      label: l10n.friendsPeopleYouMayKnow,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Share your Later card, Scan a friend's code.
class _Tiles extends StatelessWidget {
  const _Tiles();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = context.select<FriendsStore, String?>((s) => s.uid);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tile(
              label: l10n.friendsShareCardTile,
              onTap: () => AppRoutes.toShareProfile(context),
              picture: me == null ? const SizedBox() : _CardPreview(uid: me),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Tile(
              label: l10n.friendsScanTile,
              onTap: () => AppRoutes.scanProfileQr(context),
              picture: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(AppIcons.friendsQrScan, width: 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.onTap,
    required this.picture,
  });

  final String label;
  final VoidCallback onTap;
  final Widget picture;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: AppPressable(
      child: CardV2(
        child: InkWell(
          onTap: onTap,
          child: ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 62, child: picture),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.bold,
                      color: context.palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The user's cover with their stamp on it: a small Later card.
class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 96,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          top: 0,
          width: 80,
          height: 54,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: UserBackgroundImage(userId: uid),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: UserStamp(userId: uid, size: 30, tilt: 4),
        ),
      ],
    ),
  );
}

/// The requests the user received (Accept, Not now), then the ones they
/// sent (Cancel).
class _Requests extends StatelessWidget {
  const _Requests({required this.actions});

  final FriendActions actions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final store = context.watch<FriendsStore>();
    final directory = context.watch<UserDirectory>();
    final received = store.receivedFrom.toList()..sort();
    final sent = store.sentTo.toList()..sort();

    ({String name, String username, int mutual}) who(String uid) {
      final p = directory.profile(uid);
      return (
        name: p?.name ?? l10n.commonUnknownUser,
        username: p?.username ?? l10n.commonUnknownUsername,
        mutual: p?.friends.where(store.friendIds.contains).length ?? 0,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (received.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Text(
                  l10n.friendsRequestsEmptyTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.friendsNoRequestsHint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    height: 1.35,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else ...[
          GroupLabelV2(l10n.friendsAskedToBeFriend),
          CardV2Rows(
            indent: PersonRowV2.indentFor(FriendRequestsReceivedRow.stampSize),
            children: [
              for (final uid in received)
                if (who(uid) case final w)
                  FriendRequestsReceivedRow(
                    key: ValueKey(uid),
                    uid: uid,
                    name: w.name,
                    username: w.username,
                    mutualFriends: w.mutual,
                    isBusy: store.isBusy(uid),
                    onTap: () => AppRoutes.toAddFriendProfile(context, uid),
                    onAccept: () => actions.acceptRequest(uid),
                    onReject: () => actions.rejectRequest(uid),
                  ),
            ],
          ),
        ],
        if (sent.isNotEmpty) ...[
          const SizedBox(height: 8),
          GroupLabelV2(l10n.friendsSentByYou),
          CardV2Rows(
            indent: PersonRowV2.indentFor(46),
            children: [
              for (final uid in sent)
                if (who(uid) case final w)
                  FriendRequestsSentRow(
                    key: ValueKey(uid),
                    uid: uid,
                    name: w.name,
                    username: w.username,
                    isBusy: store.isBusy(uid),
                    onTap: () => AppRoutes.toAddFriendProfile(context, uid),
                    onCancel: () => actions.cancelRequest(uid),
                  ),
            ],
          ),
        ],
      ],
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../../../shared/widgets/default_search_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../settings/settings_store.dart';
import '../../users/user_directory.dart';
import '../friends_store.dart';
import '../pinned_friends_controller.dart';
import '../widgets/friend_options_modal.dart';
import '../widgets/my_friends/my_friends_grouped_by_letter_list.dart';
import '../widgets/my_friends/pinned_friends_row.dart';

/// My friends (Figma page 14, `7190:972`): the search with the QR button,
/// the friends pinned on the profile, then everyone A to Z and a count.
class MyFriendsPage extends StatefulWidget {
  const MyFriendsPage({super.key});

  @override
  State<MyFriendsPage> createState() => _MyFriendsPageState();
}

class _MyFriendsPageState extends State<MyFriendsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  /// The pins live in the settings, so this one stays in step with the
  /// profile's own controller.
  late final PinnedFriendsController _pins;

  @override
  void initState() {
    super.initState();
    _pins = PinnedFriendsController(
      friends: context.read<FriendsStore>(),
      settings: context.read<SettingsStore>(),
    );
    _searchController.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _query = _searchController.text.trim().toLowerCase());
        }
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _pins.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final store = context.watch<FriendsStore>();
    final directory = context.watch<UserDirectory>();

    final ids = store.friendIds;
    final loading =
        !store.isLoaded ||
        ids.any((uid) {
          directory.profile(uid);
          return !directory.isResolved(uid);
        });

    Widget body;
    if (loading) {
      body = const Center();
    } else {
      final friends = [
        for (final uid in ids)
          directory.profile(uid) ?? UserProfile.unknown(uid),
      ];
      final grouped = groupFriendsByInitial(friends, _query);
      if (grouped.isEmpty) {
        body = DefaultEmptyInboxInfo(
          message: _query.isEmpty ? l10n.friendsEmpty : l10n.friendsNoMatches,
          assetPath: AppIcons.profileFriendSearch,
        );
      } else {
        body = MyFriendsGroupedByLetterList(
          groupedFriends: grouped,
          header: _query.isEmpty
              ? ChangeNotifierProvider.value(
                  value: _pins,
                  child: const PinnedFriendsRow(),
                )
              : null,
          footer: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              l10n.friendsCount(ids.length),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: palette.textSecondary,
              ),
            ),
          ),
          // The friend's menu; removing them here keeps this page open.
          onMore: (uid) =>
              FriendOptionsModal.show(context, uid, leavePage: false),
        );
      }
    }

    return Scaffold(
      backgroundColor: palette.background,
      body: Column(
        children: [
          PageHeaderV2(
            title: l10n.friendsMyFriendsTitle,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l10n.commonBack,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: DefaultSearchBar(
              controller: _searchController,
              hintText: l10n.friendsSearchHint,
              trailingButton: DefaultIconButton(
                onTap: () => AppRoutes.scanProfileQr(context),
                assetPath: AppIcons.friendsQrScan,
                semanticLabel: l10n.friendsQrTitle,
                size: 30,
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Friends matching [query], grouped by initial (a friend with an empty
/// name goes under "#" instead of crashing, BUG-077).
Map<String, List<UserProfile>> groupFriendsByInitial(
  Iterable<UserProfile> friends,
  String query,
) {
  final grouped = <String, List<UserProfile>>{};
  for (final f in friends) {
    if (query.isNotEmpty &&
        !f.name.toLowerCase().contains(query) &&
        !f.username.toLowerCase().contains(query)) {
      continue;
    }
    grouped.putIfAbsent(f.initial, () => []).add(f);
  }
  for (final list in grouped.values) {
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
  return grouped;
}

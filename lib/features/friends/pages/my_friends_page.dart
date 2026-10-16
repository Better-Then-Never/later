import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/router/app_routes.dart';
import '../../../core/assets/app_assets.dart';
import '../../../data/models/user_profile.dart';
import '../../../shared/widgets/buttons/default_icon_button.dart';
import '../../../shared/widgets/default_empty_inbox_info.dart';
import '../../../shared/widgets/default_search_bar.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/buttons/go_back_button.dart';
import '../../users/user_directory.dart';
import '../friends_store.dart';
import '../widgets/my_friends/my_friends_grouped_by_letter_list.dart';

/// All friends grouped by first letter, with a local search.
class MyFriendsPage extends StatefulWidget {
  const MyFriendsPage({super.key});

  @override
  State<MyFriendsPage> createState() => _MyFriendsPageState();
}

class _MyFriendsPageState extends State<MyFriendsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
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
      body = grouped.isEmpty
          ? DefaultEmptyInboxInfo(
              message: _query.isEmpty
                  ? 'No friends added yet'
                  : 'No friends match your search',
              assetPath: AppIcons.profileFriendSearch,
            )
          : MyFriendsGroupedByLetterList(
              groupedFriends: grouped,
              screenWidth: screenWidth,
            );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          PageHeader(
            mainText: 'My friends',
            leadingButton: GoBackButton(context: context),
            searchBar: DefaultSearchBar(
              controller: _searchController,
              hintText: 'Find my friends',
              trailingButton: DefaultIconButton(
                onTap: () => AppRoutes.scanProfileQr(context),
                assetPath: AppIcons.friendsQrScan,
                size: screenWidth * 0.09,
              ),
            ),
          ),
          Expanded(child: body),
          const SizedBox(height: 24),
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

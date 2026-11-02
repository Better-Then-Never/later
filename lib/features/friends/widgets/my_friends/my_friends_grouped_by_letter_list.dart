import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../data/models/user_profile.dart';
import '../../../../shared/motion/app_motion_widgets.dart';
import '../../../../shared/widgets/v2/card_v2.dart';
import '../friend_stamp.dart';

/// Everyone A to Z: a letter label, then a card of the friends under it
/// (stamp, name, @username, the ⋯ menu). A tap opens the friend's profile.
class MyFriendsGroupedByLetterList extends StatelessWidget {
  const MyFriendsGroupedByLetterList({
    super.key,
    required this.groupedFriends,
    required this.onMore,
    this.header,
    this.footer,
  });

  final Map<String, List<UserProfile>> groupedFriends;

  /// The friend's menu.
  final ValueChanged<String> onMore;

  /// Above the letters (the pinned friends).
  final Widget? header;

  /// Below the letters (the count).
  final Widget? footer;

  static const _stamp = 44.0;

  @override
  Widget build(BuildContext context) {
    final sortedKeys = groupedFriends.keys.toList()..sort();
    final extra = header == null ? 0 : 1;

    return AppStaggerScope(
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        itemCount: extra + sortedKeys.length + 1,
        itemBuilder: (context, index) {
          if (index < extra) return header!;
          final i = index - extra;
          if (i == sortedKeys.length) return footer ?? const SizedBox();
          final letter = sortedKeys[i];
          final group = groupedFriends[letter]!;
          return AppStaggerItem(
            key: ValueKey(letter),
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GroupLabelV2(letter),
                  CardV2Rows(
                    indent: PersonRowV2.indentFor(_stamp),
                    children: [
                      for (final friend in group)
                        PersonRowV2(
                          key: ValueKey(friend.uid),
                          userId: friend.uid,
                          name: friend.name,
                          subtitle: '@${friend.username}',
                          stampSize: _stamp,
                          onTap: () =>
                              AppRoutes.toFriendProfile(context, friend.uid),
                          trailing: MoreDotsButton(
                            semanticLabel: context.l10n.friendsMoreFor(
                              friend.name,
                            ),
                            onTap: () => onMore(friend.uid),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

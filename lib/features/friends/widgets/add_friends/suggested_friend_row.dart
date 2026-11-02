import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../data/models/friend_request.dart';
import '../../../../shared/widgets/pill_v2.dart';
import '../friend_stamp.dart';

/// One suggestion: the stamp, the name, "@username · mutual friends", then
/// "+ Add" (or "Requested") and hide.
///
/// Only a request the user sent shows "Requested"; a request the user
/// received shows Accept, which accepts it (BUG-070).
class SuggestedFriendRow extends StatelessWidget {
  final String userId;
  final String name;
  final String username;

  /// Friends in common, shown after the username when there are any.
  final int mutualFriends;
  final FriendRelation relation;
  final VoidCallback onTapProfile;
  final VoidCallback onSendRequest;
  final VoidCallback onRemove;

  const SuggestedFriendRow({
    super.key,
    required this.userId,
    required this.name,
    required this.username,
    this.mutualFriends = 0,
    required this.relation,
    required this.onTapProfile,
    required this.onSendRequest,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pill = switch (relation) {
      FriendRelation.requestSent => PillV2(
        label: l10n.friendsRequested,
        kind: PillV2Kind.outline,
        size: PillV2Size.small,
      ),
      FriendRelation.requestReceived => Semantics(
        label: l10n.friendsAcceptRequestLabel,
        child: PillV2(
          label: l10n.friendsAccept,
          size: PillV2Size.small,
          onTap: onSendRequest,
        ),
      ),
      _ => Semantics(
        label: l10n.friendsSendRequestLabel,
        child: PillV2(
          label: l10n.friendsAddPlus,
          kind: PillV2Kind.soft,
          size: PillV2Size.small,
          onTap: onSendRequest,
        ),
      ),
    };
    return PersonRowV2(
      userId: userId,
      name: name,
      subtitle: personSubtitle(context, username, mutualFriends),
      stampSize: 46,
      onTap: onTapProfile,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill,
          Semantics(
            button: true,
            label: l10n.friendsHideSuggestionLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onRemove,
              // A 44 dp tap target around a smaller picture (D-24).
              child: SizedBox.square(
                dimension: 44,
                child: Center(
                  child: Image.asset(
                    AppIcons.friendsDeleteReset,
                    width: 18,
                    height: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

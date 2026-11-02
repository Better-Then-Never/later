import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../shared/widgets/pill_v2.dart';
import '../friend_stamp.dart';

/// A friend request the user received: the stamp, the name, "@username ·
/// mutual friends", then Accept and Not now (declines it).
class FriendRequestsReceivedRow extends StatelessWidget {
  final String name;
  final String username;
  final String uid;

  /// Friends the user and the sender have in common.
  final int mutualFriends;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onTap;
  final VoidCallback onReject;

  const FriendRequestsReceivedRow({
    super.key,
    required this.name,
    required this.username,
    required this.uid,
    this.mutualFriends = 0,
    this.isBusy = false,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
  });

  static const stampSize = 46.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PersonRowV2(
      userId: uid,
      name: name,
      subtitle: personSubtitle(context, username, mutualFriends),
      stampSize: stampSize,
      onTap: onTap,
      below: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          PillV2(
            label: l10n.friendsAccept,
            size: PillV2Size.small,
            onTap: isBusy ? null : onAccept,
          ),
          PillV2(
            label: l10n.friendsNotNow,
            kind: PillV2Kind.outline,
            size: PillV2Size.small,
            onTap: isBusy ? null : onReject,
          ),
        ],
      ),
    );
  }
}

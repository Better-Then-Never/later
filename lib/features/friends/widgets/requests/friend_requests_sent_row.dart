import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../shared/widgets/pill_v2.dart';
import '../friend_stamp.dart';

/// A friend request the user sent: the stamp, the name, @username and
/// Cancel.
class FriendRequestsSentRow extends StatelessWidget {
  final String name;
  final String username;
  final String uid;
  final bool isBusy;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const FriendRequestsSentRow({
    super.key,
    required this.name,
    required this.username,
    required this.uid,
    this.isBusy = false,
    required this.onTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return PersonRowV2(
      userId: uid,
      name: name,
      subtitle: '@$username',
      stampSize: 46,
      onTap: onTap,
      trailing: PillV2(
        label: context.l10n.commonCancel,
        kind: PillV2Kind.outline,
        size: PillV2Size.small,
        onTap: isBusy ? null : onCancel,
      ),
    );
  }
}

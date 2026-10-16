import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/count_badge.dart';
import '../friends_store.dart';

/// Red pill with the number of received friend requests (hidden at 0).
///
/// Callers position it; it used to return its own `Positioned`, which broke
/// when placed inside another `Positioned` (BUG-082).
class FriendRequestCountBadge extends StatelessWidget {
  const FriendRequestCountBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<FriendsStore, int>((s) => s.incomingCount);
    return CountBadge(count: count);
  }
}

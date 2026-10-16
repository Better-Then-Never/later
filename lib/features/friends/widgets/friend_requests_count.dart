import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    if (count == 0) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'Irina',
          ),
        ),
      ),
    );
  }
}

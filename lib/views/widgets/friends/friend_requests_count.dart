import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_friends_service.dart';

class FriendRequestCountBadge extends StatelessWidget {
  const FriendRequestCountBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserFriendsService>(
      builder: (context, friendsService, child) {
        final count = friendsService.receivedRequests.length;
        if (count == 0) return const SizedBox.shrink();

        final displayCount = count > 99 ? '99+' : count.toString();

        return Positioned(
          top: 15,
          right: 12,
          child: Container(
            constraints: const BoxConstraints(minWidth: 20),
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                displayCount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Irina',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/services/user_data_service.dart';
import 'package:provider/provider.dart';

class FriendRequestCountBadge extends StatelessWidget {
  const FriendRequestCountBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserDataService>(
      context,
      listen: false,
    ).currentLoggedInUid;

    return StreamBuilder<int>(
      stream: UserFriendsService.getReceivedRequestsCount(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == 0) return SizedBox.shrink();

        final count = snapshot.data!;
        final displayCount = count > 99 ? '99+' : count.toString();

        return Positioned(
          top: 15,
          right: 12,
          child: Container(
            constraints: BoxConstraints(minWidth: 20),
            height: 20,
            padding: EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                displayCount,
                style: TextStyle(
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

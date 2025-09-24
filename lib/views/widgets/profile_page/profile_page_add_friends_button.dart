import 'package:flutter/material.dart';
import 'package:later/views/widgets/common//default_text.dart';
import 'package:later/views/widgets/common/decorations/box_decorations.dart';
import 'package:later/services/profile_friends/friend_request_helper.dart';

class ProfilePageAddFriendsButton extends StatelessWidget {
  final String currentUserUid;

  const ProfilePageAddFriendsButton({super.key, required this.currentUserUid});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/addFriendsPage');
      },
      child: Container(
        width: screenWidth - 32,
        height: 45,
        decoration: BoxDecorations.whiteCard(),
        child: Stack(
          children: [
            Positioned(
              top: 3,
              left: 0,
              right: 0,
              child: Row(
                children: [
                  const SizedBox(width: 18),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Image.asset(
                      'assets/images/icons/prof_page/add_friend.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 18),
                  const DefaultText(
                    'Add friends',
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                ],
              ),
            ),
            StreamBuilder<int>(
              stream: FriendRequestHelper.getReceivedRequestsCount(
                currentUserUid,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == 0) {
                  return const SizedBox.shrink();
                }

                final count = snapshot.data!;
                final displayCount = count > 99 ? '99+' : count.toString();

                return Positioned(
                  top: 13,
                  right: 16,
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
            ),
          ],
        ),
      ),
    );
  }
}

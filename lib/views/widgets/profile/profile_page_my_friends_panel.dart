import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_buttons/default_text_button.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/friends/friends_row_profile.dart';
import 'package:later/views/widgets/profile/profile_page_divider.dart';

class ProfilePageMyFriendsPanel extends StatelessWidget {
  final String currentUserUid;
  final double screenWidth;

  const ProfilePageMyFriendsPanel({
    super.key,
    required this.currentUserUid,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: screenWidth - 32,
          height: 150,
          decoration: BoxDecorations.whiteCard(),
        ),

        /* Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21),
            child: Align(
              alignment: Alignment.topCenter,
              child: RandomFriendsRow(currentUserUid: currentUserUid),
            ),
          ),
        ),*/
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: screenWidth - 32,
            height: 45,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 3,
          left: 0,
          right: 0,
          child: Row(
            children: [
              const SizedBox(width: 18),
              SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  'assets/images/icons/prof_page/my_friends.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: screenWidth - 95,
                height: 40,
                child: DefaultTextButton(
                  onTap: () {
                    Navigator.pushNamed(context, '/myFriendsPage');
                  },
                  text: 'My friends',
                ),
              ),
            ],
          ),
        ),

        Positioned(
          bottom: 45,
          left: 0,
          child: ProfilePageDivider(width: screenWidth - 32),
        ),
      ],
    );
  }
}

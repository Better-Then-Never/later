import 'package:flutter/material.dart';
import 'package:later/controllers/widget_controllers/profile/pinned_friends_controller.dart';
import 'package:later/services/user_data_service.dart';
import 'package:later/services/user_friends_service.dart';
import 'package:later/views/pages/friends_pages/my_friends_page.dart';
import 'package:later/views/widgets/_common/default_buttons/default_text_button.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/my_profile_page/my_friends_panel/pinned_friends_row.dart';
import 'package:later/views/widgets/my_profile_page/profile_page_divider.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';

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
    final userFriendsService = Provider.of<UserFriendsService>(
      context,
      listen: false,
    );

    final userDataService = Provider.of<UserDataService>(
      context,
      listen: false,
    );

    return Stack(
      children: [
        Container(
          width: screenWidth - 32,
          height: 150,
          decoration: BoxDecorations.whiteCard(),
        ),

        Positioned(
          bottom: 35,
          left: 0,
          right: 0,
          child: ChangeNotifierProvider(
            create: (context) => PinnedFriendsController(
              friendsService: userFriendsService,
              userDataService: userDataService,
            ),
            child: PinnedFriendsRow(),
          ),
        ),
        
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
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        duration: const Duration(milliseconds: 10),
                        reverseDuration: const Duration(milliseconds: 10),
                        child: MyFriendsPage(),
                      ),
                    );
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

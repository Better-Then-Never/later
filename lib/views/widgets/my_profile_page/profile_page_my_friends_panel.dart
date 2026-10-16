import 'package:flutter/material.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/app/router/app_routes.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/friends/friends_store.dart';
import 'package:later/features/friends/pinned_friends_controller.dart';
import 'package:later/views/widgets/_common/default_buttons/default_text_button.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/my_profile_page/my_friends_panel/pinned_friends_row.dart';
import 'package:later/views/widgets/my_profile_page/profile_page_divider.dart';
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
              friends: context.read<FriendsStore>(),
              prefs: context.read<PreferencesStore>(),
            ),
            child: const PinnedFriendsRow(),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: screenWidth - 32,
            height: 45,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.only(
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
                  AppIcons.profileMyFriends,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: screenWidth - 95,
                height: 40,
                child: DefaultTextButton(
                  onTap: () => AppRoutes.toMyFriends(context),
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

import 'package:flutter/material.dart';
import 'package:later/views/widgets/my_profile_page/profile_page_add_friends_button.dart';
import 'package:later/views/widgets/my_profile_page/profile_page_header.dart';
import 'package:later/views/widgets/my_profile_page/profile_page_my_capsules_panel.dart';
import 'package:later/views/widgets/my_profile_page/profile_page_my_friends_panel.dart';
import 'package:provider/provider.dart';
import 'package:later/services/user_data_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final userProfileService = context.read<UserDataService>();
    final uid = userProfileService.currentLoggedInUid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: Column(
        children: [
          ProfilePageHeader(screenWidth: screenWidth),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 16),
                const ProfilePageMyCapsulesPanel(),
                const SizedBox(height: 16),
                ProfilePageAddFriendsButton(currentUserUid: uid),
                const SizedBox(height: 8),
                ProfilePageMyFriendsPanel(
                  currentUserUid: uid,
                  screenWidth: screenWidth,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

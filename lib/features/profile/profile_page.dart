import 'package:flutter/material.dart';
import 'package:later/features/profile/widgets/profile_page_add_friends_button.dart';
import 'package:later/features/profile/widgets/profile_page_header.dart';
import 'package:later/features/profile/widgets/profile_page_my_capsules_panel.dart';
import 'package:later/features/profile/widgets/profile_page_my_friends_panel.dart';
import 'package:provider/provider.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/app/shell/navbar_widget.dart';
import 'package:later/core/config/feature_flags.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/features/achievements/achievements_view.dart';

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

    // Only built while signed in (AuthGate), never the old 'No User'.
    final uid = context.read<SessionController>().uid!;
    final profile = context.select<SessionController, UserProfile?>(
      (s) => s.profile,
    );

    return Scaffold(
      backgroundColor: context.palette.background,
      body: Column(
        children: [
          ProfilePageHeader(screenWidth: screenWidth, userId: uid),
          // Scrolls under the fixed header (it used to be a fixed Column:
          // nothing below the friends could be reached, F-39).
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                NavbarWidget.coveredHeight(context) + 16,
              ),
              child: Column(
                children: [
                  const ProfilePageMyCapsulesPanel(),
                  const SizedBox(height: 16),
                  ProfilePageAddFriendsButton(currentUserUid: uid),
                  const SizedBox(height: 8),
                  ProfilePageMyFriendsPanel(
                    currentUserUid: uid,
                    screenWidth: screenWidth,
                  ),
                  if (FeatureFlags.achievements && profile != null) ...[
                    const SizedBox(height: 16),
                    AchievementsPanel(profile: profile),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

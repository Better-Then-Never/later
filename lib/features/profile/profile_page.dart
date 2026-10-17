import 'package:flutter/material.dart';
import 'package:later/features/profile/widgets/profile_capsules_card.dart';
import 'package:later/features/profile/widgets/profile_friends_card.dart';
import 'package:later/features/profile/widgets/profile_page_add_friends_button.dart';
import 'package:later/features/profile/widgets/profile_page_header.dart';
import 'package:provider/provider.dart';
import 'package:later/app/router/app_page_route.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/theme/app_palette.dart';
import 'package:later/core/theme/app_text_styles.dart';
import 'package:later/app/shell/navbar_widget.dart';
import 'package:later/core/config/feature_flags.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/achievements/achievements_view.dart';
import 'package:later/features/friends/friends_store.dart';
import 'package:later/features/friends/pinned_friends_controller.dart';
import 'package:later/features/messages/chats_store.dart';
import 'package:later/features/settings/pages/about_settings_page.dart';
import 'package:later/features/settings/settings_store.dart';
import 'package:later/shared/widgets/user/user_about_line.dart';

/// The user's own profile: header, a few words about them, their capsules in
/// numbers, friends (pinned and recent, with quick actions) and achievements
/// (F-54, F-56, F-85).
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
                4,
                16,
                NavbarWidget.coveredHeight(context) + 16,
              ),
              child: Column(
                children: [
                  _OwnAbout(about: profile?.about ?? ''),
                  const ProfileCapsulesCard(),
                  const SizedBox(height: 12),
                  ProfilePageAddFriendsButton(currentUserUid: uid),
                  const SizedBox(height: 8),
                  ChangeNotifierProvider(
                    create: (context) => PinnedFriendsController(
                      friends: context.read<FriendsStore>(),
                      settings: context.read<SettingsStore>(),
                      chats: context.read<ChatsStore>(),
                      prefs: context.read<PreferencesStore>(),
                    ),
                    child: const ProfileFriendsCard(),
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

/// The user's "about me", which opens its editor; an invitation to write
/// one when there is none.
class _OwnAbout extends StatelessWidget {
  const _OwnAbout({required this.about});

  final String about;

  @override
  Widget build(BuildContext context) {
    final text = about.trim();
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(
          context,
        ).push(appRoute<void>(const AboutSettingsPage())),
        child: text.isNotEmpty
            ? AboutText(text)
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  context.l10n.profileAboutPrompt,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandGreen,
                  ),
                ),
              ),
      ),
    );
  }
}

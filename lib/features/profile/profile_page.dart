import 'package:flutter/material.dart';
import 'package:later/features/profile/postcard/own_postcard.dart';
import 'package:later/features/profile/postcard/postcard_scaffold.dart';
import 'package:later/features/profile/postcard/profile_postcard.dart';
import 'package:later/features/profile/widgets/profile_capsules_card.dart';
import 'package:later/features/profile/widgets/profile_friends_card.dart';
import 'package:later/features/profile/widgets/profile_page_add_friends_button.dart';
import 'package:later/features/profile/widgets/profile_places_card.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/shared/widgets/v2/card_v2.dart';
import 'package:provider/provider.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/app/shell/navbar_widget.dart';
import 'package:later/core/config/feature_flags.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/data/services/preferences_store.dart';
import 'package:later/features/achievements/achievements_view.dart';
import 'package:later/features/friends/friends_store.dart';
import 'package:later/features/friends/pinned_friends_controller.dart';
import 'package:later/features/messages/chats_store.dart';
import 'package:later/features/settings/settings_store.dart';

/// The user's own profile (Profile v4, Figma page 13): the postcard, then
/// their capsules in numbers, friends (pinned and recent, with quick
/// actions) and achievements. See [PostcardScaffold] for how the postcard
/// opens, closes and becomes a strip.
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
    final profile = context.select<SessionController, UserProfile?>(
      (s) => s.profile,
    );
    final uid = context.read<SessionController>().uid!;
    final l10n = context.l10n;

    return PostcardScaffold(
      postcard: (context, open) => OwnPostcard(open: open),
      strip: ProfilePhotoStrip(
        cover: const OwnCover(),
        stamp: OwnStamp(
          size: 56,
          tilt: -4,
          style: profile?.stamp ?? const ProfileStampStyle(),
          initial: profile?.initial ?? '',
        ),
        name: profile?.name ?? '',
        username: profile?.username ?? '',
      ),
      buttons: const PostcardButtons(),
      bottomPadding: NavbarWidget.coveredHeight(context) + 16,
      // Under the postcard, the Profile v2 body (Figma 7182:4354): a titled
      // section each for capsules, friends, places and achievements.
      body: [
        const SizedBox(height: 4),
        SectionTitleV2(l10n.profileMyCapsules),
        const ProfileCapsulesCard(),
        SectionTitleV2(l10n.profileFriendsSection),
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
        SectionTitleV2(l10n.profilePlacesSection),
        const ProfilePlacesCard(),
        if (FeatureFlags.achievements && profile != null) ...[
          SectionTitleV2(l10n.achievementsTitle),
          AchievementsPanel(profile: profile),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:later/app/router/app_page_route.dart';
import 'package:later/app/router/app_routes.dart';
import 'package:later/app/session/session_controller.dart';
import 'package:later/core/assets/app_assets.dart';
import 'package:later/data/models/capsule.dart';
import 'package:later/features/profile/postcard/postcard_scaffold.dart';
import 'package:later/features/profile/postcard/profile_postcard.dart';
import 'package:later/features/profile/postcard/user_postcard.dart';
import 'package:later/features/profile/share/sharing_service.dart';
import 'package:later/features/friends/widgets/friend_options_modal.dart';
import 'package:later/features/friends/widgets/profile/friend_capsules_strip.dart';
import 'package:later/core/l10n/l10n.dart';
import 'package:later/core/config/feature_flags.dart';
import 'package:later/data/models/user_profile.dart';
import 'package:later/features/achievements/achievements_view.dart';
import 'package:later/features/users/user_directory.dart';
import 'package:later/features/world/world_page.dart';
import 'package:later/shared/widgets/user/user_background_image.dart';
import 'package:later/shared/widgets/user/user_stamp.dart';
import 'package:later/shared/widgets/v2/card_v2.dart';
import 'package:provider/provider.dart';

/// A friend's profile (Profile v4, Figma page 13 `7185:4831`): their
/// postcard with their stamp, then Open chat and Send a capsule well below
/// their words, their capsules, their Passport and their achievements.
class YourFriendProfilePage extends StatelessWidget {
  final String friendUid;

  const YourFriendProfilePage({super.key, required this.friendUid});

  @override
  Widget build(BuildContext context) {
    final friend = context.select<UserDirectory, UserProfile?>(
      (d) => d.profile(friendUid),
    );
    final l10n = context.l10n;
    final first = (friend?.name ?? '').split(' ').first;
    final stats = friend?.stats;

    return PostcardScaffold(
      postcard: (context, open) => UserPostcard(userId: friendUid, open: open),
      strip: ProfilePhotoStrip(
        cover: UserBackgroundImage(userId: friendUid),
        stamp: UserStamp(userId: friendUid, size: 56, tilt: -4),
        name: friend?.name ?? '',
        username: friend?.username ?? '',
        leading: const SizedBox(width: 40),
      ),
      leading: PostcardIconButton(
        asset: AppIcons.goBackCircle,
        label: l10n.commonBack,
        onTap: () => Navigator.pop(context),
      ),
      buttons: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PostcardIconButton(
            asset: AppIcons.share,
            label: l10n.friendsShareProfile,
            onTap: () => SharingService.shareUserProfile(
              context: context,
              userId: friendUid,
            ),
          ),
          PostcardIconButton(
            asset: AppIcons.openMenu,
            label: MaterialLocalizations.of(context).showMenuTooltip,
            onTap: () => FriendOptionsModal.show(context, friendUid),
          ),
        ],
      ),
      body: [
        // Clear of their words (they touched in v2).
        const SizedBox(height: 16),
        CardV2Rows(
          children: [
            RowV2(
              iconPath: AppIcons.sendMessage,
              title: l10n.friendsOpenChat,
              onTap: () => AppRoutes.toChat(context, friendUid),
            ),
            RowV2(
              iconPath: AppIcons.sendCapsule,
              title: l10n.friendsSendCapsule,
              onTap: () => AppRoutes.toCamera(
                context,
                privacy: CapsulePrivacy.private,
                recipientId: friendUid,
              ),
            ),
          ],
        ),
        SectionTitleV2(
          first.isEmpty
              ? l10n.friendsFriendCapsulesTitle
              : l10n.profileFriendCapsules(first),
        ),
        FriendCapsulesStrip(friendUid: friendUid),
        SectionTitleV2(l10n.profilePlacesSection),
        CardV2(
          child: RowV2(
            iconPath: AppIcons.capsuleLocation,
            title: first.isEmpty
                ? l10n.worldTitle
                : l10n.profileFriendPassport(first),
            subtitle: stats == null
                ? null
                : l10n.profileCountriesTowns(
                    l10n.profileCountries(stats.countries),
                    l10n.profileTowns(stats.cities),
                  ),
            onTap: () => Navigator.of(context).push(
              appRoute<void>(
                // Opens at You and <friend>.
                WorldPage(
                  uid: friendUid,
                  viewerUid: context.read<SessionController>().uid,
                ),
              ),
            ),
          ),
        ),
        // Shown when the friend shares them (Settings > Privacy).
        if (FeatureFlags.achievements &&
            friend != null &&
            friend.showAchievements) ...[
          const SizedBox(height: 16),
          AchievementsPanel(profile: friend),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/user_profile.dart';
import '../../../shared/widgets/user/user_background_image.dart';
import '../../../shared/widgets/user/user_stamp.dart';
import '../../../shared/widgets/user/verified_name.dart';
import '../../users/user_directory.dart';
import 'own_postcard.dart';
import 'profile_postcard.dart';

/// Someone else's postcard (Profile v4): their cover, their stamp in the
/// shape and colour they chose, name, town, what they wrote and their
/// numbers. Nothing on it is editable.
class UserPostcard extends StatelessWidget {
  const UserPostcard({super.key, required this.userId, required this.open});

  final String userId;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final profile = context.select<UserDirectory, UserProfile?>(
      (d) => d.profile(userId),
    );
    final palette = context.palette;
    final about = profile?.about.trim() ?? '';
    final town = profile?.homeTown.trim() ?? '';
    final username = profile?.username ?? '';
    return ProfilePostcard(
      photoHeight: open
          ? ProfilePostcard.photoOpen
          : ProfilePostcard.photoDefault,
      cover: UserBackgroundImage(userId: userId),
      stamp: UserStamp(
        userId: userId,
        size: ProfilePostcard.stampSize,
        tilt: -5,
        small: false,
        elevation: 3,
      ),
      name: VerifiedName(
        uid: userId,
        name: profile?.name ?? '',
        maxLines: 2,
        style: AppTextStyles.body.copyWith(
          fontSize: 26,
          height: 1.15,
          fontWeight: FontWeight.bold,
          color: palette.textPrimary,
        ),
      ),
      subtitle: Text(
        username.isEmpty
            ? ''
            : (town.isEmpty ? '@$username' : '@$username  ·  $town'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.body.copyWith(
          fontSize: 14,
          color: palette.textSecondary,
        ),
      ),
      about: about.isEmpty
          ? const SizedBox.shrink()
          : StampSpeechBubble(
              child: Text(about, style: StampSpeechBubble.textStyle(context)),
            ),
      counts: PostcardCounts(profile: profile),
    );
  }
}

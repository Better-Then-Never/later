import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/users/user_directory.dart';
import '../default_text.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_colors.dart';

/// Name above "@username" of any user, from [UserDirectory], with the
/// verified badge after the name and, with [showCounts], the follower and
/// following counts the server keeps (F-53, F-58).
class UserNameAndUsername extends StatelessWidget {
  final String userId;

  final TextAlign textAlign;
  final double nameFontSize;
  final double usernameFontSize;

  /// Theme text colours when null.
  final Color? nameColor;
  final Color? usernameColor;
  final FontWeight nameFontWeight;
  final FontWeight usernameFontWeight;
  final CrossAxisAlignment crossAxisAlignment;

  const UserNameAndUsername({
    super.key,
    required this.userId,
    this.textAlign = TextAlign.center,
    this.nameFontSize = 32,
    this.usernameFontSize = 22,
    this.nameColor,
    this.usernameColor,
    this.nameFontWeight = FontWeight.bold,
    this.usernameFontWeight = FontWeight.bold,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.showCounts = false,
  });

  final bool showCounts;

  @override
  Widget build(BuildContext context) {
    final directory = context.watch<UserDirectory>();
    final profile = directory.profile(userId);
    if (profile == null && !directory.isResolved(userId)) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        children: const [Center(), Center()],
      );
    }
    final name = profile?.name ?? context.l10n.commonUnknownUser;
    final username = profile?.username ?? context.l10n.commonUnknownUsername;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: crossAxisAlignment == CrossAxisAlignment.start
              ? Alignment.centerLeft
              : Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DefaultText(
                name,
                fontSize: nameFontSize,
                fontWeight: nameFontWeight,
                color: nameColor ?? context.palette.textPrimary,
                textAlign: textAlign,
                height: 1.0,
              ),
              if (profile?.verified ?? false) ...[
                SizedBox(width: nameFontSize * 0.2),
                Semantics(
                  label: context.l10n.profileVerified,
                  child: Icon(
                    Icons.verified,
                    size: nameFontSize * 0.75,
                    color: AppColors.infoBlue,
                  ),
                ),
              ],
            ],
          ),
        ),
        DefaultText(
          '@$username',
          fontSize: usernameFontSize,
          color: usernameColor ?? context.palette.textSecondary,
          fontWeight: usernameFontWeight,
          textAlign: textAlign,
        ),
        if (showCounts && profile != null)
          DefaultText(
            '${context.l10n.profileFollowers(profile.followerCount)}  ·  '
            '${context.l10n.profileFollowing(profile.followingCount)}',
            fontSize: usernameFontSize * 0.7,
            color: usernameColor ?? context.palette.textSecondary,
            textAlign: textAlign,
          ),
      ],
    );
  }
}

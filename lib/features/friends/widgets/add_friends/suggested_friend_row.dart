import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../data/models/friend_request.dart';
import '../../../../shared/widgets/user/user_round_avatar.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_palette.dart';
import 'package:later/core/theme/app_text_styles.dart';

/// One suggestion: avatar, name, @username, add (or pending) and hide.
///
/// Only a request the user sent shows the pending clock; a request the
/// user received shows the add button, which accepts it (BUG-070).
class SuggestedFriendRow extends StatelessWidget {
  final String userId;
  final String name;
  final String username;
  final FriendRelation relation;
  final VoidCallback onTapProfile;
  final VoidCallback onSendRequest;
  final VoidCallback onRemove;
  final double screenWidth;

  const SuggestedFriendRow({
    super.key,
    required this.userId,
    required this.name,
    required this.username,
    required this.relation,
    required this.onTapProfile,
    required this.onSendRequest,
    required this.onRemove,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = screenWidth * 0.09;
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: onTapProfile,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          leading: UserRoundAvatar(userId: userId, radius: screenWidth * 0.07),
          title: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
              fontFamily: kAppFontFamily,
              color: context.palette.textPrimary,
            ),
          ),
          subtitle: Text(
            '@$username',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontFamily: kAppFontFamily,
              color: context.palette.textSecondary,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              relation == FriendRelation.requestSent
                  ? Image.asset(
                      AppIcons.friendsPending,
                      width: iconSize,
                      height: iconSize,
                    )
                  : Semantics(
                      button: true,
                      label: relation == FriendRelation.requestReceived
                          ? context.l10n.friendsAcceptRequestLabel
                          : context.l10n.friendsSendRequestLabel,
                      child: GestureDetector(
                        onTap: onSendRequest,
                        child: Image.asset(
                          AppIcons.profileAddFriend,
                          width: iconSize,
                          height: iconSize,
                        ),
                      ),
                    ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: context.l10n.friendsHideSuggestionLabel,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Image.asset(
                    AppIcons.friendsDeleteReset,
                    width: screenWidth * 0.07,
                    height: screenWidth * 0.07,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

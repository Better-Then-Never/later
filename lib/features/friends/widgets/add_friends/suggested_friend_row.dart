import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../data/models/friend_request.dart';
import '../../../../shared/widgets/user/user_round_avatar.dart';
import '../../../../shared/widgets/user/verified_name.dart';
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

  /// Friends in common, shown after the username when there are any.
  final int mutualFriends;
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
    this.mutualFriends = 0,
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
          leading: UserRoundAvatar(
            userId: userId,
            radius: UserRoundAvatar.listRadius(screenWidth),
          ),
          title: VerifiedName(
            uid: userId,
            name: name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
              fontFamily: kAppFontFamily,
              color: context.palette.textPrimary,
            ),
          ),
          subtitle: Text(
            mutualFriends > 0
                ? '@$username · ${context.l10n.friendsMutualCount(mutualFriends)}'
                : '@$username',
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
                      child: _Target(
                        onTap: onSendRequest,
                        child: Image.asset(
                          AppIcons.profileAddFriend,
                          width: iconSize,
                          height: iconSize,
                        ),
                      ),
                    ),
              Semantics(
                button: true,
                label: context.l10n.friendsHideSuggestionLabel,
                child: _Target(
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

/// A 44 dp tap target around a smaller picture (D-24).
class _Target extends StatelessWidget {
  const _Target({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox.square(dimension: 44, child: Center(child: child)),
  );
}

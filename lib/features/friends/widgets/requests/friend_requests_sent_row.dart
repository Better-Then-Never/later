import 'package:flutter/material.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/features/friends/widgets/requests/friend_requests_action_button.dart';
import 'package:later/shared/widgets/user/user_round_avatar.dart';
import 'package:later/core/theme/app_colors.dart';

class FriendRequestsSentRow extends StatelessWidget {
  final String name;
  final String username;
  final String uid;
  final double screenWidth;
  final bool isBusy;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const FriendRequestsSentRow({
    super.key,
    required this.name,
    required this.username,
    required this.uid,
    required this.screenWidth,
    this.isBusy = false,
    required this.onTap,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecorations.whiteCard(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              UserRoundAvatar(userId: uid, radius: screenWidth * 0.07),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultText(
                      name,
                      fontWeight: FontWeight.bold,
                      fontSize: screenWidth * 0.045,
                      color: AppColors.black,
                    ),
                    DefaultText(
                      '@$username',
                      fontSize: screenWidth * 0.035,
                      color: AppColors.grey600,
                    ),
                  ],
                ),
              ),
              FriendRequestsActionButton(
                onTap: isBusy ? null : onCancel,
                color: AppColors.danger,
                text: 'Cancel',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'user_round_avatar.dart';
import 'package:later/core/theme/app_text_styles.dart';
import '../../../core/theme/app_palette.dart';

class UserListTile extends StatelessWidget {
  final String uid;
  final String name;
  final String username;
  final double screenWidth;
  final VoidCallback? onTap;
  final Widget? trailing;

  const UserListTile({
    super.key,
    required this.uid,
    required this.name,
    required this.username,
    required this.screenWidth,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      leading: UserRoundAvatar(
        userId: uid,
        radius: UserRoundAvatar.listRadius(screenWidth),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: screenWidth * 0.045,
          fontFamily: kAppFontFamily,
          color: context.palette.textPrimary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '@$username',
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          fontFamily: kAppFontFamily,
          color: context.palette.textSecondary,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'user_avatar.dart';

class UserListTile extends StatelessWidget {
  final String name;
  final String username;
  final String? imageUrl;
  final double screenWidth;
  final VoidCallback? onTap;
  final Widget? trailing;

  const UserListTile({
    super.key,
    required this.name,
    required this.username,
    required this.imageUrl,
    required this.screenWidth,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
      leading: UserAvatar(imageUrl: imageUrl, radius: screenWidth * 0.07),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: screenWidth * 0.045,
          fontFamily: 'Irina',
          color: Colors.black,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '@$username',
        style: TextStyle(
          fontSize: screenWidth * 0.04,
          fontFamily: 'Irina',
          color: const Color.fromARGB(255, 94, 94, 94),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

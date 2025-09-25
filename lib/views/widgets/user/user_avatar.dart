import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String fallbackAsset;

  const UserAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.fallbackAsset = 'assets/images/icons/navbar/icon-profile.png',
  });

  @override
  Widget build(BuildContext context) {
    final ImageProvider avatar = (imageUrl != null && imageUrl!.isNotEmpty)
        ? NetworkImage(imageUrl!)
        : AssetImage(fallbackAsset) as ImageProvider;

    return CircleAvatar(
      radius: radius,
      backgroundImage: avatar,
      backgroundColor: Colors.grey[200],
    );
  }
}

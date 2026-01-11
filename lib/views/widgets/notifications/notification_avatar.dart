import 'package:flutter/material.dart';

class NotificationAvatar extends StatelessWidget {
  final String userAvatar;
  final double radius;

  const NotificationAvatar({
    super.key,
    required this.userAvatar,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: userAvatar.startsWith('http')
          ? NetworkImage(userAvatar)
          : AssetImage(userAvatar) as ImageProvider,
      backgroundColor: Colors.grey.shade300,
      child: userAvatar.isEmpty
          ? const Icon(Icons.person, color: Colors.white)
          : null,
    );
  }
}
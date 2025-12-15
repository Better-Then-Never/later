import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';

class FriendRequestsActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final EdgeInsetsGeometry? contentPadding;
  final String text;
  final Color color;

  const FriendRequestsActionButton({
    super.key,
    required this.onTap,
    required this.color,
    required this.text,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.01),
        decoration: BoxDecorations.defaultBorderRadius(color: color),
        child: DefaultText(
          text,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

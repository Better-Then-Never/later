import 'package:flutter/material.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/core/theme/app_colors.dart';

class FriendRequestsActionButton extends StatelessWidget {
  final VoidCallback? onTap;
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
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    // The pill keeps its look; taps land on a box at least 44 dp tall
    // around it (D-24).
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          widthFactor: 1,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.01,
            ),
            decoration: BoxDecorations.defaultBorderRadius(color: color),
            child: DefaultText(
              text,
              color: AppColors.onAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

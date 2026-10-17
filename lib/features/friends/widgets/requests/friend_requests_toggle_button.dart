import 'package:flutter/material.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/theme/app_palette.dart';

class FriendRequestsToggleButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isSelected;
  final EdgeInsetsGeometry? contentPadding;
  final String text;

  const FriendRequestsToggleButton({
    super.key,
    required this.onTap,
    required this.text,
    required this.isSelected,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 35,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandGreen : context.palette.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.brandGreen, width: 2),
          ),
          child: Center(
            child: DefaultText(
              text,
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.bold,
              color: isSelected ? AppColors.onAccent : AppColors.brandGreen,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:later/core/theme/app_colors.dart';

/// Placeholder of a user row while it loads (grey avatar and two text bars).
class UserRowSkeleton extends StatelessWidget {
  final double screenWidth;

  const UserRowSkeleton({super.key, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: 8,
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.14,
            height: screenWidth * 0.14,
            decoration: const BoxDecoration(
              color: AppColors.grey300,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: screenWidth * 0.3,
                height: screenWidth * 0.04,
                color: AppColors.grey300,
              ),
              const SizedBox(height: 4),
              Container(
                width: screenWidth * 0.2,
                height: screenWidth * 0.03,
                color: AppColors.grey300,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

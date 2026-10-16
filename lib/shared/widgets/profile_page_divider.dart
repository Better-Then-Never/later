import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ProfilePageDivider extends StatelessWidget {
  final double width;
  final double thickness;
  final Color color;

  const ProfilePageDivider({
    super.key,
    required this.width,
    this.thickness = 1,
    this.color = AppColors.divider,
  });

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: thickness, color: color);
  }
}

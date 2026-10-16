import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

class ProfilePageDivider extends StatelessWidget {
  final double width;
  final double thickness;

  /// The divider colour of the theme when null.
  final Color? color;

  const ProfilePageDivider({
    super.key,
    required this.width,
    this.thickness = 1,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: thickness,
      color: color ?? context.palette.divider,
    );
  }
}

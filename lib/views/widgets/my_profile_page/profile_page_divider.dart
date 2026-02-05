import 'package:flutter/material.dart';

class ProfilePageDivider extends StatelessWidget {
  final double width;
  final double thickness;
  final Color color;

  const ProfilePageDivider({
    super.key,
    required this.width,
    this.thickness = 1,
    this.color = const Color.fromARGB(255, 211, 211, 211),
  });

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: thickness, color: color);
  }
}

import 'package:flutter/material.dart';
import 'package:later/shared/styles/box_decorations.dart';

class ShadowTopOverlay extends StatelessWidget {
  final double width;

  const ShadowTopOverlay({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 1,
      decoration: BoxDecorations.blackShadow(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';

class DefaultButtonWithIcon extends StatelessWidget {
  final double? width;
  final double? height;
  final String assetPath;
  final VoidCallback onTap;
  final String text;
  final double? textFontSize;
  final Decoration? decoration;

  const DefaultButtonWithIcon({
    super.key,
    required this.onTap,
    this.width,
    this.height,
    required this.assetPath,
    required this.text,
    this.textFontSize,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 48,
        decoration: decoration ?? BoxDecorations.greyCard(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(assetPath, width: 32, height: 32),
            const SizedBox(width: 6),
            DefaultText('Invite friends', fontSize: 19, color: Colors.black),
          ],
        ),
      ),
    );
  }
}

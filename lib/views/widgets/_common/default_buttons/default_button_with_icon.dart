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
  final FontWeight? textFontWeight;
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
    this.textFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height ?? 48,
        decoration: decoration ?? BoxDecorations.greyCard(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(assetPath, width: 32, height: 32),
              SizedBox(width: 8.0),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: DefaultText(
                    text,
                    fontSize: textFontSize,
                    color: Colors.black,
                    fontWeight: textFontWeight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

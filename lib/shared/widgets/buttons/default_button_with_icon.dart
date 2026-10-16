import 'package:flutter/material.dart';
import 'package:later/shared/motion/app_motion_widgets.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/shared/widgets/default_text.dart';
import '../../../core/theme/app_palette.dart';

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
    return AppPressable(child: _buildButton(context));
  }

  Widget _buildButton(BuildContext context) {
    return Container(
      decoration: decoration ?? BoxDecorations.greyCard(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          splashColor: context.palette.textPrimary.withAlpha(25),
          child: Container(
            width: width,
            height: height ?? 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Image.asset(assetPath, width: 32, height: 32),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: DefaultText(
                      text,
                      fontSize: textFontSize,
                      textAlign: TextAlign.center,
                      color: context.palette.textPrimary,
                      fontWeight: textFontWeight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

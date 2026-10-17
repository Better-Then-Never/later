import 'package:flutter/material.dart';
import 'package:later/core/theme/app_colors.dart';
import 'package:later/core/theme/app_text_styles.dart';

class DefaultText extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;
  final TextAlign? textAlign;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final int? maxLines;
  final TextOverflow? overflow;

  const DefaultText(
    this.text, {
    super.key,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.textAlign,
    this.padding,
    this.height,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        text,
        textAlign: textAlign ?? TextAlign.center,
        maxLines: maxLines,
        overflow: overflow,
        style: TextStyle(
          fontFamily: kAppFontFamily,
          fontWeight: fontWeight ?? FontWeight.normal,
          fontSize: fontSize ?? 14,
          color: color ?? AppColors.black,
          height: height,
        ),
      ),
    );
  }
}

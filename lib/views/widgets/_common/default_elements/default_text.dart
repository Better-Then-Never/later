import 'package:flutter/material.dart';

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
          fontFamily: 'Irina',
          fontWeight: fontWeight ?? FontWeight.normal,
          fontSize: fontSize ?? 14,
          color: color ?? Colors.black,
          height: height,
        ),
      ),
    );
  }
}

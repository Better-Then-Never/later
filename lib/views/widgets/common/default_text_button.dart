import 'package:flutter/material.dart';
import 'package:later/views/styles/text_button_styles.dart';
import 'package:later/views/widgets/common/default_text.dart';

class DefaultTextButton extends StatelessWidget {
  final String text;
  final double? size;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? contentPadding;
  final ButtonStyle? style;

  const DefaultTextButton({
    super.key,
    required this.onTap,
    required this.text,
    this.size,
    this.contentPadding,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: contentPadding ?? EdgeInsets.zero,
      child: TextButton(
        onPressed: onTap,
        style: style ?? TextButtonStyles.profileTextButtonStyle(),
        child: DefaultText(text, fontSize: size ?? 16),
      ),
    );
  }
}

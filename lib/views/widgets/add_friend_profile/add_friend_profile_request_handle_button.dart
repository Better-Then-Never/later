import 'package:flutter/material.dart';
import 'package:later/views/styles/elevated_button_styles.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/_common/default_elements/white_circular_progress_indicator.dart';

class AddProfileRequestHandleButton extends StatelessWidget {
  final bool isCancelling;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final double fontSize;
  final String text;
  final Color? color;

  const AddProfileRequestHandleButton({
    super.key,
    required this.isCancelling,
    required this.onPressed,
    required this.width,
    required this.height,
    required this.fontSize,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecorations.softBlackShadow(),
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          style: ElevatedButtonStyles.roundedButtonStyle(color: color ?? Colors.red),
          onPressed: isCancelling ? null : onPressed,
          child: isCancelling
              ? const WhiteCircularProgressIndicator(size: 16)
              : DefaultText(
                  text,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

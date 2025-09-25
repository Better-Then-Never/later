import 'package:flutter/material.dart';
import 'package:later/views/styles/elevated_button_styles.dart';
import 'package:later/views/widgets/_common/decorations/box_decorations.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';
import 'package:later/views/widgets/_common/default_elements/white_circular_progress_indicator.dart';

class AddProfileCancelButton extends StatelessWidget {
  final bool isCancelling;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final double fontSize;

  const AddProfileCancelButton({
    super.key,
    required this.isCancelling,
    required this.onPressed,
    required this.width,
    required this.height,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecorations.softBlackShadow(),
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          style: ElevatedButtonStyles.cancelButtonStyle(),
          onPressed: isCancelling ? null : onPressed,
          child: isCancelling
              ? const WhiteCircularProgressIndicator(size: 16)
              : DefaultText(
                  'Cancel Request',
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }
}

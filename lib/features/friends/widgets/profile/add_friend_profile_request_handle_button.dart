import 'package:flutter/material.dart';
import 'package:later/shared/styles/elevated_button_styles.dart';
import 'package:later/shared/styles/box_decorations.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/shared/widgets/white_circular_progress_indicator.dart';
import 'package:later/core/theme/app_colors.dart';

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
      decoration: BoxDecorations.softBlackShadow(context),
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          style: ElevatedButtonStyles.roundedButtonStyle(
            color: color ?? AppColors.materialRed,
          ),
          onPressed: isCancelling ? null : onPressed,
          child: isCancelling
              ? const WhiteCircularProgressIndicator(size: 16)
              : DefaultText(
                  text,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:later/shared/motion/app_motion_widgets.dart';
import 'package:later/shared/widgets/default_text.dart';
import 'package:later/core/theme/app_colors.dart';

class DefaultGreenButton extends StatelessWidget {
  final String text;
  final bool? isLoading;
  final double? width;
  final double? height;
  final double? textFontSize;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;

  const DefaultGreenButton({
    super.key,
    required this.onTap,
    required this.text,
    this.isLoading,
    this.width,
    this.height,
    this.textFontSize = 30,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bool loading = isLoading ?? false;
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: AppPressable(
        enabled: !loading,
        child: ElevatedButton(
          onPressed: loading ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25.0),
            ),
            alignment: Alignment.center,
            fixedSize: Size(
              width ?? screenWidth * 0.45,
              height ?? screenHeight * 0.06,
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2,
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: DefaultText(
                    text,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: textFontSize,
                    textAlign: TextAlign.center,
                  ),
                ),
        ),
      ),
    );
  }
}

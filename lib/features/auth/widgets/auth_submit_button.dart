import 'package:flutter/material.dart';
import 'package:later/shared/motion/app_motion_widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';

/// The big green "Log In" / "Sign Up" button of the auth screens.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      enabled: !isLoading,
      child: SizedBox(
        width: 275,
        height: 55,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brandGreen,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadii.lCircular,
            ),
          ),
          child: isLoading
              ? const CircularProgressIndicator(color: AppColors.onAccent)
              // Longer translations shrink to stay on one line.
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(text, style: AppTextStyles.buttonLarge),
                ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:later/views/styles/elevated_button_styles.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';

class AddProfileMainButton extends StatelessWidget {
  final double width;
  final double height;
  final double fontSize;
  final bool isLoading;
  final VoidCallback? onPressed;

  final String buttonState;

  const AddProfileMainButton({
    super.key,
    required this.width,
    required this.height,
    required this.isLoading,
    required this.onPressed,
    required this.buttonState,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            spreadRadius: 1,
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
        borderRadius: BorderRadius.circular(25),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          style: ElevatedButtonStyles.roundedButtonStyle(
            color: _getButtonColor(),
          ),
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : DefaultText(
                  _getButtonText(),
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  String _getButtonText() {
    switch (buttonState) {
      case 'own_profile':
        return 'My Profile';
      case 'pending':
        return 'Pending';
      case 'friends':
        return 'View Profile';
      default:
        return 'Add';
    }
  }

  Color _getButtonColor() {
    switch (buttonState) {
      case 'own_profile':
        return const Color.fromARGB(255, 108, 117, 125);
      case 'pending':
        return Color.fromARGB(255, 253, 219, 7);
      case 'friends':
        return const Color.fromARGB(255, 54, 144, 255);
      default:
        return const Color.fromARGB(255, 86, 201, 46);
    }
  }
}

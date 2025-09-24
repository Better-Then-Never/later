import 'package:flutter/material.dart';
import 'package:later/views/widgets/_common/default_elements/default_text.dart';

class DefaultGreenButton extends StatelessWidget {
  final String text;
  final bool? isLoading;
  final double? width;
  final double? height;
  final double? textFontSize;
  final VoidCallback onTap;

  const DefaultGreenButton({
    super.key,
    required this.onTap,
    required this.text,
    this.isLoading,
    this.width,
    this.height,
    this.textFontSize = 30,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bool loading = isLoading ?? false;
    return ElevatedButton(
      onPressed: loading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF56C92E),
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
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: DefaultText(
                text,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: textFontSize,
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';

class WhiteCircularProgressIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const WhiteCircularProgressIndicator({
    super.key,
    this.size = 16,
    this.strokeWidth = 2,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: Colors.white,
        strokeWidth: strokeWidth,
      ),
    );
  }
}

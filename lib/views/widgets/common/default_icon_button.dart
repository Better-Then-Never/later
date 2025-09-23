import 'package:flutter/material.dart';

class DefaultIconButton extends StatelessWidget {
  final double? size;
  final VoidCallback onTap;
  final String? assetPath;
  final Widget? child;

  const DefaultIconButton({
    super.key,
    required this.onTap,
    this.size,
    this.assetPath,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child:
          child ??
          Image.asset(
            assetPath!,
            width: size ?? screenWidth * 0.11,
            height: size ?? screenWidth * 0.11,
          ),
    );
  }
}

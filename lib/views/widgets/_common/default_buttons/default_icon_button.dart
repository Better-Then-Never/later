import 'package:flutter/material.dart';

class DefaultIconButton extends StatelessWidget {
  final double? size;
  final VoidCallback onTap;
  final String? assetPath;
  final Widget? child;
  final double? opacity;
  final EdgeInsetsGeometry? contentPadding;

  const DefaultIconButton({
    super.key,
    required this.onTap,
    this.size,
    this.assetPath,
    this.child,
    this.opacity,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: opacity ?? 1,
        child:
            child ??
            Image.asset(
              assetPath!,
              width: size ?? screenWidth * 0.11,
              height: size ?? screenWidth * 0.11,
            ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:later/shared/motion/app_motion_widgets.dart';

class DefaultIconButton extends StatelessWidget {
  final double? size;
  final VoidCallback onTap;
  final String? assetPath;
  final Widget? child;
  final double? opacity;
  final EdgeInsetsGeometry? contentPadding;

  /// What a screen reader says for the button; pictures alone say nothing.
  final String? semanticLabel;

  const DefaultIconButton({
    super.key,
    required this.onTap,
    this.size,
    this.assetPath,
    this.child,
    this.opacity,
    this.contentPadding,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final button = AppPressable(
      child: GestureDetector(
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
      ),
    );
    final label = semanticLabel;
    if (label == null) return button;
    return Semantics(button: true, label: label, child: button);
  }
}

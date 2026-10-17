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

  /// The smallest area that takes the tap, however small the picture
  /// (44 × 44, docs/feel/FEEL_QA.md); the picture keeps its size, centred.
  static const minTapTarget = 44.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final button = AppPressable(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: minTapTarget,
            minHeight: minTapTarget,
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
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
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return button;
    return Semantics(button: true, label: label, child: button);
  }
}

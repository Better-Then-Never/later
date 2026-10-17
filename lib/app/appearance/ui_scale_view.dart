import 'package:flutter/widgets.dart';

/// Draws the whole interface [scale] times bigger (or smaller).
///
/// Most sizes in the app are fractions of the screen (DESIGN_SPEC.md §3), so a
/// text-size setting alone would leave icons, cards and buttons unchanged. The
/// app is laid out on a virtual screen of `size / scale` and painted scaled by
/// [scale]: everything grows or shrinks together and stays crisp (vector
/// drawing at the final resolution), and touches are mapped through the same
/// transform.
class UiScaleView extends StatelessWidget {
  const UiScaleView({super.key, required this.scale, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (scale == 1.0) return child;
    final data = MediaQuery.of(context);
    final size = data.size / scale;
    EdgeInsets s(EdgeInsets e) => e / scale;
    return MediaQuery(
      data: data.copyWith(
        size: size,
        devicePixelRatio: data.devicePixelRatio * scale,
        padding: s(data.padding),
        viewPadding: s(data.viewPadding),
        viewInsets: s(data.viewInsets),
        systemGestureInsets: s(data.systemGestureInsets),
      ),
      child: ClipRect(
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: size.width,
            maxWidth: size.width,
            minHeight: size.height,
            maxHeight: size.height,
            child: child,
          ),
        ),
      ),
    );
  }
}

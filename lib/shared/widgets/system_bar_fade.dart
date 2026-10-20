import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:later/core/theme/app_palette.dart';

/// The page colour fading in behind Android's navigation bar (G-03), so what
/// scrolls under the system buttons no longer shows through them.
///
/// It covers the bar plus [extra] above it (80 dp with three buttons, 56 dp
/// with gestures) and sits under the floating tab bar. The top edge fills in
/// over [edge], eased at both ends, to 70 %, and the bottom ends at 80 %
/// (Figma, page "11 · G-03 navigation bar"; lighter after the owner saw it
/// on the phone). Nothing is drawn without a bottom bar or while the
/// keyboard is up (the bottom padding is then 0). A plain gradient, no blur:
/// it costs nothing to draw.
class SystemBarFade extends StatelessWidget {
  const SystemBarFade({super.key, this.extra = 32});

  /// How far the fade reaches above the system bar.
  final double extra;

  /// How long the top edge takes to go from clear to [_edgeAlpha].
  static const double edge = 24;

  static const double _edgeAlpha = 0.7;
  static const double _bottomAlpha = 0.8;

  /// Points along the edge where the smoothstep curve is sampled.
  static const _samples = [0.0, 0.25, 0.5, 0.75, 1.0];

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    if (inset <= 0) return const SizedBox.shrink();
    final height = inset + extra;
    final reach = math.min(edge, height) / height;
    final page = context.palette.background;
    final stops = <double>[];
    final colors = <Color>[];
    for (final t in _samples) {
      stops.add(t * reach);
      colors.add(page.withValues(alpha: _edgeAlpha * t * t * (3 - 2 * t)));
    }
    stops.add(1);
    colors.add(page.withValues(alpha: _bottomAlpha));
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
              stops: stops,
            ),
          ),
        ),
      ),
    );
  }
}

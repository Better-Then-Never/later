import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/app_colors.dart';
import '../map_projection.dart';
import '../map_viewport.dart';
import '../marker_choreography.dart';

/// Draws the [choreography]'s sprites over the still map and runs its clock
/// while there are any (M-03, M-04). An act that lands is reported
/// ([onLanded]) so the page puts its markers on the map. Takes no touches.
class MarkerChoreographyOverlay extends StatefulWidget {
  const MarkerChoreographyOverlay({
    super.key,
    required this.choreography,
    required this.view,
    required this.version,
    required this.onLanded,
  });

  final MarkerChoreography choreography;
  final ValueListenable<MapView?> view;

  /// Changes whenever the choreography got new sprites (wakes the clock).
  final int version;
  final ValueChanged<int> onLanded;

  @override
  State<MarkerChoreographyOverlay> createState() =>
      _MarkerChoreographyOverlayState();
}

class _MarkerChoreographyOverlayState extends State<MarkerChoreographyOverlay>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _from = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _wake();
  }

  @override
  void didUpdateWidget(MarkerChoreographyOverlay old) {
    super.didUpdateWidget(old);
    _wake();
  }

  void _wake() {
    if (!widget.choreography.active || _ticker.isActive) return;
    _from = widget.choreography.ms;
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    final choreography = widget.choreography;
    final landed = choreography.advance(_from + elapsed.inMilliseconds);
    if (landed != null) widget.onLanded(landed);
    if (!choreography.active) _ticker.stop();
    setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.choreography.active) return const SizedBox.shrink();
    return ValueListenableBuilder<MapView?>(
      valueListenable: widget.view,
      builder: (context, view, _) => view == null
          ? const SizedBox.shrink()
          : CustomPaint(
              size: Size.infinite,
              painter: _SpritesPainter(
                widget.choreography.sprites,
                widget.choreography.ms,
                view,
              ),
            ),
    );
  }
}

class _SpritesPainter extends CustomPainter {
  _SpritesPainter(this.sprites, this.ms, this.view);

  final List<MarkerSprite> sprites;
  final int ms;
  final MapView view;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.medium;
    for (final sprite in sprites) {
      final pose = sprite.at(ms);
      if (pose == null || pose.scale <= 0 || pose.opacity <= 0) continue;
      final look = sprite.look;
      final spot = MapProjection.toScreen(
        pose.at,
        view.camera,
        size,
        view.padding,
      );
      final w = look.size.width * pose.scale;
      final h = look.size.height * pose.scale;
      // Anchored like the map's marker, growing around its anchor.
      final dst = Rect.fromLTWH(
        spot.dx - look.anchor.dx * w,
        spot.dy - look.anchor.dy * h,
        w,
        h,
      );
      final image = look.image;
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        dst,
        // Only its alpha counts: how see-through the picture is drawn.
        paint
          ..color = AppColors.mediaBlack.withValues(
            alpha: pose.opacity.clamp(0.0, 1.0),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_SpritesPainter old) => true;
}

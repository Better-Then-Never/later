import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../data/models/capsule.dart';
import '../map_projection.dart';
import '../map_viewport.dart';
import '../selected_pin.dart';

/// A capsule's pin drawn by Flutter over the map at its [spot] (M-02), in
/// the pose of its [motion]: it grows and jumps, sways, then hovers above a
/// soft shadow; once landing, it lands back and says so ([onLanded]). The
/// motion advances only while [running] (the map is still and its own pin
/// hidden); held, the pin keeps its pose. It follows the map ([view],
/// [MapProjection]) and takes no touches (the map below does). Reduced
/// motion: it simply hovers, and lands at once.
class SelectedPinOverlay extends StatefulWidget {
  const SelectedPinOverlay({
    super.key,
    required this.color,
    required this.spot,
    required this.view,
    required this.motion,
    this.running = true,
    this.onLanded,
  });

  final CapsuleColor color;
  final LatLng spot;
  final ValueListenable<MapView?> view;
  final PinMotion motion;
  final bool running;
  final VoidCallback? onLanded;

  /// The pins are on screen at once when a pin is tapped (none to wait for).
  static Future<void> precache(BuildContext context) => Future.wait([
    for (final c in CapsuleColor.values)
      precacheImage(AssetImage(AppIcons.mapPin(c.name)), context),
  ]);

  @override
  State<SelectedPinOverlay> createState() => _SelectedPinOverlayState();
}

class _SelectedPinOverlayState extends State<SelectedPinOverlay>
    with SingleTickerProviderStateMixin {
  /// Every frame while it jumps, sways and lands; [_hover] steps the slow
  /// hover between.
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  Timer? _hover;
  bool _reportedLanded = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SelectedPinOverlay old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// Runs the clock the motion needs now, or none.
  void _sync() {
    final motion = widget.motion;
    final reduced = AppMotion.reduced(context);
    motion.landMs = reduced ? 0 : SelectedPin.landing.inMilliseconds;
    if (!motion.landing) {
      _reportedLanded = false;
      // Reduced motion: straight to the hover, which holds still.
      if (reduced && motion.ms < SelectedPin.swayEnd) {
        motion.ms = SelectedPin.swayEnd;
      }
    }
    if (!widget.running) return _stop();
    if (motion.landing) {
      if (motion.landed) {
        _stop();
        _reportLanded();
      } else {
        _runTicker();
      }
    } else if (reduced) {
      _stop();
    } else if (motion.ms < SelectedPin.swayEnd) {
      _runTicker();
    } else {
      _runHover();
    }
  }

  void _runTicker() {
    _hover?.cancel();
    _hover = null;
    if (_ticker.isActive) return;
    _last = Duration.zero;
    _ticker.start();
  }

  void _runHover() {
    _ticker.stop();
    _hover ??= Timer.periodic(SelectedPin.hoverStep, (_) {
      setState(() => widget.motion.ms += SelectedPin.hoverStep.inMilliseconds);
    });
  }

  void _stop() {
    _ticker.stop();
    _hover?.cancel();
    _hover = null;
  }

  void _tick(Duration elapsed) {
    final step = elapsed - _last;
    _last = elapsed;
    setState(() => widget.motion.ms += step.inMilliseconds);
    _sync();
  }

  void _reportLanded() {
    if (_reportedLanded) return;
    _reportedLanded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.motion.landed) widget.onLanded?.call();
    });
  }

  @override
  void dispose() {
    _hover?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pose = widget.motion.pose;
    final lift = pose.lift;
    final side = SelectedPin.side * pose.scale;
    return LayoutBuilder(
      builder: (context, box) => ValueListenableBuilder<MapView?>(
        valueListenable: widget.view,
        builder: (context, view, _) {
          if (view == null) return const SizedBox.shrink();
          final spot = MapProjection.toScreen(
            widget.spot,
            view.camera,
            box.biggest,
            view.padding,
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: Rect.fromCenter(
                  center: spot.translate(0, -SelectedPin.tipAbove * pose.scale),
                  width: SelectedPin.shadowWidth,
                  height: SelectedPin.shadowHeight,
                ),
                child: CustomPaint(painter: _ShadowPainter(lift)),
              ),
              // Stands on its spot like the native pin, [lift] above it.
              Positioned(
                left: spot.dx - side / 2,
                top: spot.dy - lift - side,
                child: Transform.rotate(
                  angle: pose.degrees * math.pi / 180,
                  // Swings around its spot on the ground.
                  origin: Offset(0, side / 2 + lift),
                  child: Image.asset(
                    AppIcons.mapPin(widget.color.name),
                    width: side,
                    height: side,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A soft oval on the ground under the floating pin: none while it stands on
/// its spot (the native pins have none), smaller and lighter the higher it
/// floats.
class _ShadowPainter extends CustomPainter {
  _ShadowPainter(this.lift);

  final double lift;

  @override
  void paint(Canvas canvas, Size size) {
    if (lift <= 0) return;
    final strength = (lift / 6).clamp(0.0, 1.0);
    final k = (1 - lift / 40).clamp(0.6, 1.0);
    canvas.drawOval(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: 20 * k,
        height: 6 * k,
      ),
      Paint()
        ..color = AppColors.mediaBlack.withValues(alpha: 0.3 * strength)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
  }

  @override
  bool shouldRepaint(_ShadowPainter old) => old.lift != lift;
}

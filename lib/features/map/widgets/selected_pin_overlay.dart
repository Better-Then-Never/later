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

/// A capsule's pin drawn by Flutter over the map at its [spot] (M-02): it
/// grows and jumps, sways, then hovers above a soft shadow; once [landing],
/// it lands back and says so ([onLanded]). It follows the map frame by
/// frame ([view], [MapProjection]) and takes no touches (the map below
/// does). Reduced motion: it simply hovers, and lands at once.
class SelectedPinOverlay extends StatefulWidget {
  const SelectedPinOverlay({
    super.key,
    required this.color,
    required this.spot,
    required this.view,
    this.landing = false,
    this.onLanded,
  });

  final CapsuleColor color;
  final LatLng spot;
  final ValueListenable<MapView?> view;
  final bool landing;
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
  Timer? _hover;
  bool _started = false;

  /// Milliseconds since the jump began, and what they were when the ticker
  /// last started.
  int _ms = 0;
  int _tickerFrom = 0;

  /// The landing: where it began (lift, size, sway) and when.
  (double, double, double)? _landFrom;
  int _landStart = 0;
  bool _landed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      // Straight to the hover, no clock needed.
      _ms = SelectedPin.swayEnd;
    } else {
      _runTicker();
    }
    if (widget.landing) _land();
  }

  @override
  void didUpdateWidget(SelectedPinOverlay old) {
    super.didUpdateWidget(old);
    if (widget.landing && !old.landing) _land();
    if (!widget.landing && old.landing) _jumpAgain();
  }

  void _runTicker() {
    _hover?.cancel();
    _hover = null;
    _tickerFrom = _ms;
    _ticker
      ..stop()
      ..start();
  }

  void _tick(Duration elapsed) {
    setState(() => _ms = _tickerFrom + elapsed.inMilliseconds);
    if (_landFrom != null) {
      if (!_landed && _ms - _landStart >= _landMs) {
        _ticker.stop();
        _finishLanding();
      }
    } else if (_ms >= SelectedPin.swayEnd) {
      _ticker.stop();
      const step = SelectedPin.hoverStep;
      _hover = Timer.periodic(
        step,
        (_) => setState(() => _ms += step.inMilliseconds),
      );
    }
  }

  int get _landMs =>
      AppMotion.reduced(context) ? 0 : SelectedPin.landing.inMilliseconds;

  /// Starts landing from wherever the pin is now.
  void _land() {
    _landFrom = (_lift, _scale, _degrees);
    _landStart = _ms;
    if (_landMs == 0) {
      _ticker.stop();
      _hover?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => _finishLanding());
    } else {
      _runTicker();
    }
  }

  void _finishLanding() {
    if (!mounted || _landed || !widget.landing) return;
    setState(() => _landed = true);
    widget.onLanded?.call();
  }

  /// Selected again while landing: it jumps again.
  void _jumpAgain() {
    _landFrom = null;
    _landed = false;
    if (AppMotion.reduced(context)) {
      setState(() => _ms = SelectedPin.swayEnd);
    } else {
      _ms = 0;
      _runTicker();
    }
  }

  /// 0 when landing starts, 1 once it is down.
  double get _landT => _landed
      ? 1
      : _landMs == 0
      ? 0
      : Curves.easeIn.transform(((_ms - _landStart) / _landMs).clamp(0.0, 1.0));

  double get _lift {
    final from = _landFrom;
    if (from == null) return SelectedPin.liftAt(_ms);
    return from.$1 * (1 - _landT);
  }

  double get _scale {
    final from = _landFrom;
    if (from == null) return SelectedPin.scaleAt(_ms);
    return from.$2 + (1 - from.$2) * _landT;
  }

  double get _degrees {
    final from = _landFrom;
    if (from == null) return SelectedPin.rotationAt(_ms);
    return from.$3 * (1 - _landT);
  }

  @override
  void dispose() {
    _hover?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lift = _lift;
    final side = SelectedPin.side * _scale;
    final degrees = _degrees;
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
                  center: spot.translate(0, -SelectedPin.tipAbove * _scale),
                  width: 30,
                  height: 12,
                ),
                child: CustomPaint(painter: _ShadowPainter(lift)),
              ),
              // Stands on its spot like the native pin, [lift] above it.
              Positioned(
                left: spot.dx - side / 2,
                top: spot.dy - lift - side,
                child: Transform.rotate(
                  angle: degrees * math.pi / 180,
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

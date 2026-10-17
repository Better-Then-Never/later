import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_motion.dart';
import 'appearance_controller.dart';

/// Theme, language and interface-size changes fade from a still picture of
/// the old screen to the new one. The app rebuilds once, under the picture,
/// instead of every themed widget in every tab rebuilding on each frame of a
/// colour lerp (the theme switch was 14 % janky that way, PERFORMANCE.md).
///
/// Changes that do not go through [AppearanceController] (the phone switching
/// to dark while the app follows it) apply at once. Platform views (the map)
/// are not in the picture; the switches happen on settings pages, where none
/// is on screen.
class AppearanceCrossfade extends StatefulWidget {
  const AppearanceCrossfade({super.key, required this.child});

  final Widget child;

  @override
  State<AppearanceCrossfade> createState() => _AppearanceCrossfadeState();
}

class _AppearanceCrossfadeState extends State<AppearanceCrossfade>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  // Created in initState, not lazily: a first use in dispose() would look
  // up TickerMode on a deactivated element.
  late final AnimationController _fade;
  late final Animation<double> _opacity;
  late final AppearanceController _appearance;
  ui.Image? _snapshot;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: AppMotion.slow)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _clear();
      });
    _opacity = ReverseAnimation(
      CurvedAnimation(parent: _fade, curve: AppMotion.standardCurve),
    );
    _appearance = context.read<AppearanceController>()..willChange = _capture;
  }

  void _capture() {
    if (!mounted || AppMotion.reduced(context)) return;
    final boundary = _boundary.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || !boundary.hasSize) return;
    final ui.Image image;
    try {
      image = boundary.toImageSync(
        pixelRatio: MediaQuery.devicePixelRatioOf(context),
      );
    } catch (_) {
      return; // Nothing painted yet: the change simply applies at once.
    }
    _snapshot?.dispose();
    setState(() => _snapshot = image);
    _fade.forward(from: 0);
  }

  void _clear() {
    final old = _snapshot;
    if (old == null) return;
    setState(() => _snapshot = null);
    old.dispose();
  }

  @override
  void dispose() {
    if (_appearance.willChange == _capture) _appearance.willChange = null;
    _fade.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (snapshot != null)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _opacity,
                child: RawImage(
                  image: snapshot,
                  scale: MediaQuery.devicePixelRatioOf(context),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

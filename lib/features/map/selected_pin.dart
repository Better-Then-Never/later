import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The selected capsule's pin (M-02): it grows and jumps off its spot, sways
/// and settles, then hovers gently up and down above a soft shadow that marks
/// the spot; deselected, it lands back. No outline: it works for every pin
/// colour.
///
/// The motion runs in Flutter (`SelectedPinOverlay`), over the map; the
/// native marker is only hidden meanwhile. Changing a native marker
/// re-creates its bitmap on Android, so a native pin that moved blinked at
/// every step. The overlay starts and ends exactly as the native pin looks
/// (48 dp, standing on its spot), so the swaps do not show.
abstract final class SelectedPin {
  /// The native pin (MarkerIcons): 48 dp, standing on its spot.
  static const side = 48.0;

  /// The artwork's tip stands this far above the bottom of its 457 px
  /// square, where the native pin is anchored.
  static const tipAbove = side * (457 - 420) / 457;

  /// How much bigger the selected pin grows.
  static const scale = 1.14;

  /// The jump: up, down a little below the hover, settle (ms, lift in dp).
  static const _jump = <(int, double)>[(0, 0), (110, 14), (200, 6), (260, 9)];
  static int get jumpEnd => _jump.last.$1;

  /// The sway after landing: a damped swing around the spot.
  static const swayEnd = 260 + 560;
  static const _swayDegrees = 5.0;
  static const _swayPeriod = 420.0;
  static const _swayDecay = 230.0;

  /// The hover: a slow bob around [hoverLift].
  static const hoverLift = 9.0;
  static const _bob = 2.5;
  static const _bobPeriod = 1600.0;

  /// The hover is slow: a step of about a physical pixel 30 times a second
  /// looks as smooth as one every frame, for a quarter of the frames.
  static const hoverStep = Duration(milliseconds: 33);

  /// Deselected, the pin lands back on its spot.
  static const landing = Duration(milliseconds: 180);

  /// How high the pin floats above its spot [ms] after the selection.
  static double liftAt(int ms) {
    if (ms <= 0) return 0;
    if (ms < jumpEnd) {
      for (var i = 1; i < _jump.length; i++) {
        final (t1, l1) = _jump[i];
        if (ms <= t1) {
          final (t0, l0) = _jump[i - 1];
          final t = (ms - t0) / (t1 - t0);
          // Rising slows near the top; falling speeds up; landing eases out.
          final curve = l1 > l0 ? Curves.easeOut : Curves.easeIn;
          return l0 + (l1 - l0) * curve.transform(t);
        }
      }
    }
    if (ms < swayEnd) return hoverLift;
    final t = (ms - swayEnd) / _bobPeriod;
    return hoverLift + _bob * math.sin(2 * math.pi * t);
  }

  /// How big the pin is [ms] after the selection: it grows as it rises.
  static double scaleAt(int ms) {
    final rise = _jump[1].$1;
    if (ms >= rise) return scale;
    if (ms <= 0) return 1;
    return 1 + (scale - 1) * Curves.easeOut.transform(ms / rise);
  }

  /// The sway in degrees [ms] after the selection (0 outside it).
  static double rotationAt(int ms) {
    if (ms < jumpEnd || ms >= swayEnd) return 0;
    final t = (ms - jumpEnd).toDouble();
    // Fades to exactly upright at the end: no snap into the hover.
    final fade = 1 - t / (swayEnd - jumpEnd);
    return _swayDegrees *
        fade *
        math.exp(-t / _swayDecay) *
        math.sin(2 * math.pi * t / _swayPeriod);
  }

  /// Where the markers of [ids] stand, for those on the map (not inside a
  /// cluster, not off screen).
  static Map<String, LatLng> spots(Set<Marker> markers, Iterable<String> ids) {
    final wanted = {for (final id in ids) MarkerId(id)};
    if (wanted.isEmpty) return const {};
    return {
      for (final m in markers)
        if (wanted.contains(m.markerId)) m.markerId.value: m.position,
    };
  }

  /// [markers] with those of [ids] invisible (the overlay draws them); the
  /// same set when none of them is on the map.
  static Set<Marker> hide(Set<Marker> markers, Iterable<String> ids) {
    final hidden = {for (final id in ids) MarkerId(id)};
    if (!markers.any((m) => hidden.contains(m.markerId))) return markers;
    return {
      for (final m in markers)
        hidden.contains(m.markerId) ? m.copyWith(alphaParam: 0) : m,
    };
  }
}

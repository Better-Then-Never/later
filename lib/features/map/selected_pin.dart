import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// How a floating pin stands: how high it floats above its spot (dp), how
/// big it is (1 = the native pin) and how far it leans (degrees, clockwise).
typedef SelectedPinPose = ({double lift, double scale, double degrees});

/// The selected capsule's pin (M-02): it grows and jumps off its spot, sways
/// and settles, then hovers gently up and down above a soft shadow that marks
/// the spot; deselected, it lands back. No outline: it works for every pin
/// colour.
///
/// While the map is still the motion runs in Flutter (`SelectedPinOverlay`)
/// and the native marker hides: changing a native marker re-creates its
/// bitmap on Android, so a native pin that moved blinked at every step. While
/// the map moves the map draws the pin itself, held in its pose ([apply]): a
/// Flutter overlay trails a moving map (the map reports its camera after
/// drawing, in bursts). Every hand-over happens while the map is still, from
/// the same pose, so it does not show. The shadow is the map's from the
/// selection to the landing: two see-through shadows over each other during
/// a hand-over flashed darker.
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

  // The map's own pin in a pose (MarkerIcons draws the bitmaps): the grown
  // pin at the top of a taller bitmap, its anchor lifting it off its spot
  // and its rotation leaning it; and the still shadow on its spot.

  /// The grown pin's bitmap, with room below it to float [maxLift] dp.
  static const pinSide = side * scale;
  static const maxLift = 20.0;
  static const pinHeight = pinSide + maxLift;

  /// The shadow's bitmap, drawn as under the hovering pin, centred under the
  /// grown pin's tip.
  static const shadowWidth = 30.0;
  static const shadowHeight = 12.0;
  static const shadowAnchor = Offset(
    0.5,
    0.5 + tipAbove * scale / shadowHeight,
  );

  /// Above the clusters (1) and the other pins (0).
  static const shadowZ = 2;
  static const pinZ = 3;

  /// The pin's anchor for [lift]: its bottom [lift] dp above the spot.
  static Offset anchorFor(double lift) =>
      Offset(0.5, (pinSide + lift.clamp(0.0, maxLift)) / pinHeight);

  static MarkerId shadowId(String id) => MarkerId('_shadow_$id');
  static MarkerId posedId(String id) => MarkerId('_posed_$id');

  /// [markers] as the floating pins need them: those of [hidden] invisible
  /// (Flutter draws them, or the map in their pose); for those of [posed] a
  /// pin of their own, drawn by the map in that pose with its grown bitmap;
  /// under those of [shadowed] the [shadow]. The same set when none of them
  /// is on the map.
  ///
  /// The posed pin is a marker of its own, added and removed, and the
  /// capsule's marker does not change: a changed marker gets its bitmap
  /// again and is missing from the map until it has loaded (a blink on
  /// every touch), an added one shows at once.
  static Set<Marker> apply(
    Set<Marker> markers, {
    Iterable<String> hidden = const [],
    Map<String, (SelectedPinPose, BitmapDescriptor)> posed = const {},
    Iterable<String> shadowed = const [],
    BitmapDescriptor? shadow,
  }) {
    final hide = {for (final id in hidden) MarkerId(id)};
    final poses = {
      for (final MapEntry(:key, :value) in posed.entries) MarkerId(key): value,
    };
    final shade = {
      if (shadow != null)
        for (final id in shadowed) MarkerId(id),
    };
    if (!markers.any(
      (m) =>
          hide.contains(m.markerId) ||
          poses.containsKey(m.markerId) ||
          shade.contains(m.markerId),
    )) {
      return markers;
    }
    return {
      for (final m in markers) ...[
        if (hide.contains(m.markerId)) m.copyWith(alphaParam: 0) else m,
        if (shade.contains(m.markerId))
          Marker(
            markerId: shadowId(m.markerId.value),
            position: m.position,
            icon: shadow!,
            anchor: shadowAnchor,
            zIndexInt: shadowZ,
            consumeTapEvents: true,
          ),
        if (poses[m.markerId] case (final pose, final pin))
          Marker(
            markerId: posedId(m.markerId.value),
            position: m.position,
            icon: pin,
            anchor: anchorFor(pose.lift),
            rotation: pose.degrees,
            zIndexInt: pinZ,
            consumeTapEvents: m.consumeTapEvents,
            onTap: m.onTap,
          ),
      ],
    };
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
}

/// Where a floating pin is in its motion. Its overlay advances it while the
/// map is still; the map page reads it to pose the map's own pin the same
/// while the map moves, and the overlay goes on from there.
class PinMotion {
  /// Milliseconds of motion since the jump began (held while the map moves).
  int ms = 0;

  /// How long landing takes (none with reduced motion; the overlay sets it).
  int landMs = SelectedPin.landing.inMilliseconds;

  SelectedPinPose? _landFrom;
  int _landStart = 0;

  bool get landing => _landFrom != null;
  bool get landed => landing && ms - _landStart >= landMs;

  /// Deselected: lands from wherever it is now.
  void land() {
    if (landing) return;
    _landFrom = pose;
    _landStart = ms;
  }

  /// Selected again: jumps again from its spot.
  void jumpAgain() {
    _landFrom = null;
    ms = 0;
  }

  SelectedPinPose get pose {
    final from = _landFrom;
    if (from == null) {
      return (
        lift: SelectedPin.liftAt(ms),
        scale: SelectedPin.scaleAt(ms),
        degrees: SelectedPin.rotationAt(ms),
      );
    }
    final t = landMs <= 0
        ? 1.0
        : Curves.easeIn.transform(((ms - _landStart) / landMs).clamp(0.0, 1.0));
    return (
      lift: from.lift * (1 - t),
      scale: from.scale + (1 - from.scale) * t,
      degrees: from.degrees * (1 - t),
    );
  }
}

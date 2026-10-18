import 'dart:ui';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The selected capsule's pin (M-02): it jumps off its spot, sways once and
/// rests hovering above a soft shadow that marks where it belongs, above the
/// other pins. No outline: it works for every pin colour. Only that one native
/// marker is updated, a few times per selection (a mass marker update is what
/// froze the map before; docs/feel/PERFORMANCE.md).
abstract final class SelectedPin {
  /// The jump, one bitmap each: scale of the pin, how high its tip floats
  /// above the spot (dp) and the shadow's strength. The last one stays.
  static const frames = <({double scale, double lift, double shadow})>[
    (scale: 1.10, lift: 13, shadow: 0.16),
    (scale: 1.16, lift: 6, shadow: 0.30),
    (scale: 1.14, lift: 9, shadow: 0.26),
  ];

  /// The sway after landing, in degrees around the spot (the marker's
  /// rotation; no new bitmaps).
  static const sway = <double>[7, -5, 0];

  /// Time per step: jump and sway take about 330 ms (`AppMotion.reveal`).
  static const stepTime = Duration(milliseconds: 55);

  static int get steps => frames.length + sway.length;

  /// Drawn above the clusters (1) and the other pins (0).
  static const zIndex = 2;

  /// Logical size of a frame: room for the grown pin, the lift and the
  /// shadow. The marker is anchored at the shadow's centre (the spot).
  static const width = 64.0;
  static const height = 84.0;
  static const shadowFromBottom = 4.0;
  static const anchor = Offset(0.5, 1 - shadowFromBottom / height);

  /// The bitmap of [step] (the last one after the jump).
  static int frameAt(int step) =>
      step < frames.length ? step : frames.length - 1;

  /// The rotation of [step] (0 during the jump).
  static double rotationAt(int step) => step < frames.length
      ? 0
      : sway[(step - frames.length).clamp(0, sway.length - 1)];

  /// [markers] with the one of [selectedId] drawn with [icon] at [rotation],
  /// anchored at its spot and on top; the same set when nothing is selected or
  /// its pin is not on the map (inside a cluster, off screen).
  static Set<Marker> apply(
    Set<Marker> markers,
    String? selectedId,
    BitmapDescriptor? icon, {
    double rotation = 0,
  }) {
    if (selectedId == null || icon == null) return markers;
    final id = MarkerId(selectedId);
    Marker? found;
    for (final m in markers) {
      if (m.markerId == id) {
        found = m;
        break;
      }
    }
    if (found == null) return markers;
    return {
      for (final m in markers)
        if (m.markerId != id) m,
      found.copyWith(
        iconParam: icon,
        anchorParam: anchor,
        rotationParam: rotation,
        zIndexIntParam: zIndex,
      ),
    };
  }
}

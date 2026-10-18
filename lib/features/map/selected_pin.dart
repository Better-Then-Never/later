import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The selected capsule's pin (M-02): it pops to about 1.3× with a
/// brand-green ring, frame by frame, and sits above the others. Only that one
/// native marker is updated, a few times per selection (a mass marker update
/// is what froze the map before; docs/feel/PERFORMANCE.md).
abstract final class SelectedPin {
  /// Scale of the pin and opacity of the ring per frame: a quick overshoot,
  /// then it settles (the last frame stays while the capsule is selected).
  static const frames = <({double scale, double ring})>[
    (scale: 1.10, ring: 0.35),
    (scale: 1.24, ring: 0.7),
    (scale: 1.34, ring: 1),
    (scale: 1.28, ring: 1),
  ];

  /// Time per frame: the pop takes about 240 ms (within `AppMotion.reveal`).
  static const frameTime = Duration(milliseconds: 60);

  /// Drawn above the clusters (1) and the other pins (0).
  static const zIndex = 2;

  /// [markers] with the one of [selectedId] drawn with [icon] on top; the
  /// same set when nothing is selected or its pin is not on the map (inside
  /// a cluster, off screen).
  static Set<Marker> apply(
    Set<Marker> markers,
    String? selectedId,
    BitmapDescriptor? icon,
  ) {
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
      found.copyWith(iconParam: icon, zIndexIntParam: zIndex),
    };
  }
}

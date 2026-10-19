/// How far the MapLibre map goes (mission 2, §2.3): never so far out that a
/// phone shows the whole world as a plain ocean without a label (the owner's
/// recording), never so far in that the tiles are just blown up.
///
/// No pan bounds: the plugin builds them from two corners with MapLibre's
/// LatLngBounds.Builder, which takes the shorter way round, so a world-wide
/// longitude span (-180 to 180) became a line on the date line and held the
/// camera over the Pacific (seen in the gesture harness, 19 Oct 2026).
abstract final class MapLimits {
  /// About a continent across a phone: country names show, and the heat
  /// still shows a city as a spot of its own (MapZoomVisuals.heatRadius).
  static const minZoom = 3.0;

  /// Street level with room to spare (the tiles end at 14 and are drawn
  /// larger beyond).
  static const maxZoom = 19.0;

  /// [zoom] within the limits.
  static double zoom(double zoom) => zoom.clamp(minZoom, maxZoom);
}

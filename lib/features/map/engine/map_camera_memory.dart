/// Where the map was when it last stopped, kept on this phone per account, so
/// a cold start opens there at once, before any location fix (M-06). Saved as
/// "lat,lng,zoom".
abstract final class MapCameraMemory {
  static const key = 'map_camera';

  static String format(double latitude, double longitude, double zoom) =>
      '${latitude.toStringAsFixed(5)},'
      '${longitude.toStringAsFixed(5)},'
      '${zoom.toStringAsFixed(2)}';

  /// (latitude, longitude, zoom); null when missing or broken.
  static (double, double, double)? parse(String? saved) {
    final parts = saved?.split(',');
    if (parts == null || parts.length != 3) return null;
    final values = [for (final p in parts) double.tryParse(p)];
    if (values.contains(null)) return null;
    final [lat, lng, zoom] = values.cast<double>();
    if (lat.abs() > 85 || lng.abs() > 180 || zoom < 1 || zoom > 21) {
      return null;
    }
    return (lat, lng, zoom);
  }
}

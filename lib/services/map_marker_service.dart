import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerService {
  static Future<BitmapDescriptor> loadIcon(
    String assetPath, {
    Size size = const Size(46, 46),
  }) async {
    try {
      final config = const ImageConfiguration();
      return BitmapDescriptor.asset(config, assetPath);
    } catch (_) {
      return BitmapDescriptor.defaultMarker;
    }
  }
}

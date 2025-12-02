import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerService {
  static Future<BitmapDescriptor> loadIcon(
    String assetPath, {
    Size size = const Size(46, 46),
  }) async {
    try {
      final config = ImageConfiguration(size: size);
      return await BitmapDescriptor.fromAssetImage(config, assetPath);
    } catch (_) {
      return BitmapDescriptor.defaultMarker;
    }
  }
}

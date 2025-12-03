import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapMarkerService {
  static Future<BitmapDescriptor> loadIcon(
    String assetPath, {
    Size size = const Size(46, 46),
  }) async {
    return BitmapDescriptor.asset(ImageConfiguration(size: size), assetPath);
  }
}
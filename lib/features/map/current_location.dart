import 'package:flutter/foundation.dart';

import '../../data/models/geo_position.dart';

/// Last known device position, shared by the map (which keeps it updated),
/// the history list (distances) and capsule creation (where to pin).
/// Replaces the mutable static `MapPage.currentPositionStatic`.
class CurrentLocation extends ChangeNotifier {
  GeoPosition? _position;

  GeoPosition? get position => _position;

  void update(GeoPosition? position) {
    if (position == null || position == _position) return;
    _position = position;
    notifyListeners();
  }
}

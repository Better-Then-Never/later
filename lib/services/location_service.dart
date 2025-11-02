import 'dart:async';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  final Location _locationController = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  final StreamController<LatLng> _locationStreamController =
      StreamController<LatLng>.broadcast();

  Stream<LatLng> get locationStream => _locationStreamController.stream;

  Future<void> startLocationUpdates() async {
    _locationController.changeSettings(interval: 5000, distanceFilter: 10);

    _locationSubscription = _locationController.onLocationChanged.listen((
      currentLocation,
    ) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        _locationStreamController.add(
          LatLng(currentLocation.latitude!, currentLocation.longitude!),
        );
      }
    });
  }

  Future<LatLng?> getCurrentLocation() async {
    final currentLocation = await _locationController.getLocation();
    if (currentLocation.latitude != null && currentLocation.longitude != null) {
      return LatLng(currentLocation.latitude!, currentLocation.longitude!);
    }
    return null;
  }

  void dispose() {
    _locationSubscription?.cancel();
    _locationStreamController.close();
  }
}

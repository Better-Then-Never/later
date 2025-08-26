import 'dart:async';
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationService {
  final Location _locationController = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  final StreamController<LatLng> _locationStreamController =
      StreamController<LatLng>.broadcast();

  Stream<LatLng> get locationStream => _locationStreamController.stream;

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _locationController
        .hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }

    return true;
  }

  Future<void> startLocationUpdates() async {
    final hasPermission = await _checkPermissions();
    if (!hasPermission) return;

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
    final hasPermission = await _checkPermissions();
    if (!hasPermission) return null;

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

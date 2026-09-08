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
    try {
      bool serviceEnabled = await _locationController.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _locationController.requestService();
      }

      PermissionStatus permissionGranted =
          await _locationController.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _locationController.requestPermission();
      }

      _locationController.changeSettings(interval: 5000, distanceFilter: 10);

      final initialLocation = await _locationController.getLocation();
      if (initialLocation.latitude != null &&
          initialLocation.longitude != null) {
        _locationStreamController.add(
          LatLng(initialLocation.latitude!, initialLocation.longitude!),
        );
      }
    } catch (e) {
      // Fallback location for emulator / permission denied
      _locationStreamController.add(const LatLng(37.422, -122.084));
    }

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

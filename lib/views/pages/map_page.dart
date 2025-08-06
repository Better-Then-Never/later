import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController controller;
  LatLng? currentLatLng;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Request permission
    final status = await Permission.location.request();
    if (!status.isGranted) {
      debugPrint("Location permission denied");
      return;
    }

    // Get current location
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );

    setState(() {
      currentLatLng = LatLng(position.latitude, position.longitude);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (currentLatLng == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GoogleMap(
      cloudMapId: '1b016f650a3b702f3fd1d9e1',
      initialCameraPosition: CameraPosition(target: currentLatLng!, zoom: 15),
      onMapCreated: (GoogleMapController mapController) {
        controller = mapController;
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}

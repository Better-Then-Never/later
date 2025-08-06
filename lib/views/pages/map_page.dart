import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with AutomaticKeepAliveClientMixin {
  late GoogleMapController controller;
  StreamSubscription<Position>? positionStream;

  LatLng? currentLatLng;

  @override
  void initState() {
    super.initState();
    initialize();
    startLocationUpdates();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> initialize() async {
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

  void startLocationUpdates() {
    positionStream =
        Geolocator.getPositionStream(
          locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
        ).listen((Position position) {
          setState(() {
            currentLatLng = LatLng(position.latitude, position.longitude);
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
      compassEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}

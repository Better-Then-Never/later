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

class _MapPageState extends State<MapPage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  late GoogleMapController controller;
  StreamSubscription<Position>? positionStream;

  LatLng? currentLatLng;

  bool locationDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    positionStream?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && locationDenied) {
      final status = await Permission.location.status;
      if (status.isGranted) {
        setState(() {
          locationDenied = false;
        });
        initialize();
      }
    }
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> initialize() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      setState(() {
        locationDenied = true;
      });
      return;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    setState(() {
      currentLatLng = LatLng(position.latitude, position.longitude);
    });

    startLocationUpdates();
  }

  void startLocationUpdates() {
    positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) {
          if (mounted) {
            setState(() {
              currentLatLng = LatLng(position.latitude, position.longitude);
            });
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (locationDenied) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Location permission is required to use the map."),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
              },
              child: const Text("Open App Settings"),
            ),
          ],
        ),
      );
    }

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

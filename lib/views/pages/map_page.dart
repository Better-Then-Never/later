import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late GoogleMapController mapController;

  final LatLng center = const LatLng(-23.5557714, -46.6395571);

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      cloudMapId: '1b016f650a3b702f3fd1d9e1',
      initialCameraPosition: CameraPosition(target: center, zoom: 15),
      onMapCreated: onMapCreated,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      compassEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }
}

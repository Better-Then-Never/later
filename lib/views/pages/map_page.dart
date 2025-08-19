import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:later/services/location/location_service.dart';
import 'package:later/services/map/marker_icon.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:later/views/widgets/map/capsule_info_widget.dart';

class MapPage extends StatefulWidget {
  static LatLng? currentPositionStatic;
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _mapController = Completer();
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  final Map<MarkerId, Marker> _markers = {};
  final LocationService _locationService = LocationService();

  LatLng? _currentPosition;
  LatLng? get currentPosition => _currentPosition;
  String? uid;

  final Map<String, BitmapDescriptor> _capsuleIcons = {};

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;

    _initIcons();

    _locationService.startLocationUpdates();
    _locationService.locationStream.listen((pos) {
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        MapPage.currentPositionStatic = pos;
      });
    });
  }

  Future<void> _initIcons() async {
    _capsuleIcons['red'] = await MarkerIcon.loadIcon(
      'assets/images/icons/map/pins/red_pin.png',
    );
    _capsuleIcons['blue'] = await MarkerIcon.loadIcon(
      'assets/images/icons/map/pins/blue_pin.png',
    );
    _capsuleIcons['green'] = await MarkerIcon.loadIcon(
      'assets/images/icons/map/pins/green_pin.png',
    );

    _capsuleIcons['user'] = await MarkerIcon.loadIcon(
      'assets/images/icons/map/pins/user_pin.png',
      size: Size(64, 64),
    );

    setState(() {}); // rebuild after icons are ready
  }

  @override
  void dispose() {
    _locationService.dispose();
    _customInfoWindowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('capsules').snapshots(),
      builder: (context, capsuleSnapshot) {
        if (!capsuleSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        _markers.clear();

        _markers[const MarkerId("_currentLocation")] = Marker(
          markerId: const MarkerId("_currentLocation"),
          icon: _capsuleIcons['user']!,
          position: _currentPosition!,
        );

        for (var doc in capsuleSnapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final GeoPoint geoPoint = data['location'];
          final capsulePos = LatLng(geoPoint.latitude, geoPoint.longitude);
          final capsuleId = doc.id;

          final color = 'red';
          final icon = _capsuleIcons[color];

          _markers[MarkerId(capsuleId)] = Marker(
            markerId: MarkerId(capsuleId),
            position: capsulePos,
            icon: icon!,
            onTap: () {
              _customInfoWindowController.addInfoWindow!(
                CapsuleInfoPanel(
                  title: data['title'],
                  onMoreInfo: () => _showCapsuleInfo(data),
                ),
                capsulePos,
              );
            },
          );
        }

        return Stack(
          children: [
            GoogleMap(
              onMapCreated: (controller) {
                _mapController.complete(controller);
                _customInfoWindowController.googleMapController = controller;
              },
              cloudMapId: '1b016f650a3b702f3fd1d9e1',
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 13,
              ),
              markers: Set<Marker>.of(_markers.values),
              onTap: (_) {
                _customInfoWindowController.hideInfoWindow!();
              },
              onCameraMove: (position) {
                _customInfoWindowController.onCameraMove!();
              },
            ),
            CustomInfoWindow(
              controller: _customInfoWindowController,
              height: 130,
              width: 200,
              offset: 50,
            ),
          ],
        );
      },
    );

    //TODO: Show My Location Button
    /*Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.newLatLng(pos));
  }*/
  }

  void _showCapsuleInfo(Map<String, dynamic> capsuleData) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(capsuleData['description'] ?? 'Capsule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (capsuleData['imageUrl'] != null)
              Image.network(capsuleData['imageUrl']),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  //'1b016f650a3b702f3fd1d9e1'
}

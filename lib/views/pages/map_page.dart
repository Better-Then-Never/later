import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:later/services/location/location_service.dart';
import 'package:later/services/map/marker_icon.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:later/views/widgets/map/capsule_info_widget.dart';
import 'package:intl/intl.dart';
import 'package:later/views/widgets/map/opened_capsule_widget.dart';
import 'package:later/views/widgets/loading/later_loading_bar.dart';

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
  final Map<String, String> _iconPaths = {
    'red': 'assets/images/icons/map/pins/red_pin.png',
    'blue': 'assets/images/icons/map/pins/blue_pin.png',
    'green': 'assets/images/icons/map/pins/green_pin.png',
    'yellow': 'assets/images/icons/map/pins/yellow_pin.png',
    'user': 'assets/images/icons/map/pins/user_pin.png',
  };

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
    for (final entry in _iconPaths.entries) {
      _capsuleIcons[entry.key] = await MarkerIcon.loadIcon(
        entry.value,
        size: entry.key == 'user' ? const Size(64, 64) : const Size(48, 48),
      );
    }
    setState(() {});
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
      return Center(child: LaterLoadingBar(width: 150, height: 150));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('capsules').snapshots(),
      builder: (context, capsuleSnapshot) {
        if (!capsuleSnapshot.hasData) {
          return const Center(child: LaterLoadingBar(width: 150, height: 150));
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
          final icon = _capsuleIcons[data['color']];

          _markers[MarkerId(capsuleId)] = Marker(
            markerId: MarkerId(capsuleId),
            position: capsulePos,
            icon: icon!,
            onTap: () {
              _customInfoWindowController.addInfoWindow!(
                CapsuleInfoPanel(
                  title: data['title'],
                  dateStamp: DateFormat(
                    'dd-MM-yyyy',
                  ).format(data['createdAt'].toDate()),
                  openAt: data['openAt'] ?? Timestamp.now(),
                  onMoreInfo: () => _showCapsuleInfo(context, data),
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
              height: 140,
              width: 230,
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

  void _showCapsuleInfo(
    BuildContext context,
    Map<String, dynamic> capsuleData,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: CapsulePreviewCard(capsuleData: capsuleData),
        );
      },
    );
  }

  //'1b016f650a3b702f3fd1d9e1'
}

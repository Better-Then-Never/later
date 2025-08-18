import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Location _locationController = Location();
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentPosition;
  String? uid;

  StreamSubscription<LocationData>? _locationSubscription;

  final Map<MarkerId, Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser?.uid;
    getLocationUpdates();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PermissionStatus>(
      future: _locationController.hasPermission(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        //TODO: Handle Location Permission Properly
        final permission = snapshot.data;
        if (permission != PermissionStatus.granted) {
          return Center(
            child: Text("We need location permission to use the map"),
          );
        }

        if (_currentPosition == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('capsules').snapshots(),
          builder: (context, capsuleSnapshot) {
            if (!capsuleSnapshot.hasData)
              return const Center(child: CircularProgressIndicator());

            _markers.clear();

            _markers[MarkerId("_currentLocation")] = Marker(
              markerId: const MarkerId("_currentLocation"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ), // or any hue
              position: _currentPosition!,
            );

            for (var doc in capsuleSnapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final GeoPoint geoPoint =
                  data['location']; // GeoPoint from Firestore
              final capsulePos = LatLng(
                geoPoint.latitude,
                geoPoint.longitude,
              ); // access properties directly
              final capsuleId = doc.id;

              _markers[MarkerId(capsuleId)] = Marker(
                markerId: MarkerId(capsuleId),
                position: capsulePos,
                infoWindow: InfoWindow(
                  title: data['description'] ?? 'Capsule',
                  snippet: "Tap for details",
                  onTap: () => _showCapsuleInfo(data),
                ),
              );
            }

            return GoogleMap(
              onMapCreated: (controller) => _mapController.complete(controller),
              cloudMapId: '1b016f650a3b702f3fd1d9e1',
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 13,
              ),
              markers: Set<Marker>.of(_markers.values),
            );
          },
        );
      },
    );
  }

  //TODO: Show My Location Button
  /*Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    await controller.animateCamera(CameraUpdate.newLatLng(pos));
  }*/

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
            Text('Owner: ${capsuleData['ownerId'] ?? 'Unknown'}'),
          ],
        ),
      ),
    );
  }

  Future<void> getLocationUpdates() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _locationController.changeSettings(interval: 5000, distanceFilter: 10);

    _locationSubscription = _locationController.onLocationChanged.listen((
      LocationData currentLocation,
    ) {
      if (!mounted) return;
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentPosition = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
        });
      }
    });
  }
}
//'1b016f650a3b702f3fd1d9e1'
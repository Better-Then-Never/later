import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:later/services/location_service.dart';
import 'package:later/services/map_marker_service.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:later/views/widgets/map/capsule_info_widget.dart';
import 'package:intl/intl.dart';
import 'package:later/views/widgets/map/opened_capsule_widget.dart';
import 'package:later/views/widgets/_common/default_elements/later_loading_bar.dart';

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
  final Set<Heatmap> _heatmaps = {};
  final LocationService _locationService = LocationService();

  double _currentZoom = 13.0;
  final double _markerZoomThreshold = 12.0;

  LatLng? _currentPosition;
  LatLng? get currentPosition => _currentPosition;
  String? uid;
  List<String> _userFriends = [];

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
    _loadUserFriends();

    _locationService.startLocationUpdates();
    _locationService.locationStream.listen((pos) {
      if (!mounted) return;
      setState(() {
        _currentPosition = pos;
        MapPage.currentPositionStatic = pos;
      });
    });
  }

  Future<void> _loadUserFriends() async {
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final friends = userData['friends'] as List<dynamic>? ?? [];
        setState(() {
          _userFriends = friends.cast<String>();
        });
      }
    } catch (e) {
      print('Error loading user friends: $e');
    }
  }

  bool _canViewCapsule(Map<String, dynamic> capsuleData) {
    final privacy = capsuleData['privacy'] as String? ?? 'public';
    final ownerId = capsuleData['ownerId'] as String?;

    if (ownerId == uid) {
      return true;
    }

    if (privacy == 'public') {
      return true;
    }

    if (privacy == 'friends') {
      return _userFriends.contains(ownerId);
    }

    if (privacy == 'private') {
      return false;
    }

    return false;
  }

  Future<void> _initIcons() async {
    for (final entry in _iconPaths.entries) {
      _capsuleIcons[entry.key] = await MapMarkerService.loadIcon(
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
        _heatmaps.clear();

        _markers[const MarkerId("_currentLocation")] = Marker(
          markerId: const MarkerId("_currentLocation"),
          icon: _capsuleIcons['user']!,
          position: _currentPosition!,
        );

        final List<WeightedLatLng> heatmapData = [];

        for (var doc in capsuleSnapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          if (!_canViewCapsule(data)) {
            continue;
          }

          final GeoPoint geoPoint = data['location'];
          final capsulePos = LatLng(geoPoint.latitude, geoPoint.longitude);
          final capsuleId = doc.id;
          final icon = _capsuleIcons[data['color']];

          heatmapData.add(WeightedLatLng(capsulePos, weight: 1.0));
          if (_currentZoom >= _markerZoomThreshold) {
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
        }

        _heatmaps.add(
          Heatmap(
            heatmapId: const HeatmapId("capsules_heatmap"),
            data: heatmapData,
            radius: HeatmapRadius.fromPixels(50),
            gradient: HeatmapGradient([
              HeatmapGradientColor(Colors.green, 0.2),
              HeatmapGradientColor(Colors.yellow, 0.5),
              HeatmapGradientColor(Colors.red, 1.0),
            ]),
          ),
        );

        return Stack(
          children: [
            GoogleMap(
              onMapCreated: (controller) {
                _mapController.complete(controller);
                _customInfoWindowController.googleMapController = controller;
              },
              cloudMapId: '1b016f650a3b702f3fd1d9e1',
              // Remove cloudMapId to rule out API/Style linkage issues on iOS.
              initialCameraPosition: CameraPosition(
                target: _currentPosition!,
                zoom: 13,
              ),

              markers: Set<Marker>.of(
                _markers.values.where(
                  (m) =>
                      m.icon != BitmapDescriptor.defaultMarker ||
                      _capsuleIcons.isNotEmpty,
                ),
              ),
              onTap: (_) {
                _customInfoWindowController.hideInfoWindow!();
              },
              onCameraMove: (position) {
                _customInfoWindowController.onCameraMove!();

                if ((_currentZoom - position.zoom).abs() > 0.1) {
                  setState(() {
                    _currentZoom = position.zoom;
                  });
                }
              },

              heatmaps: _heatmaps.isEmpty ? {} : _heatmaps,
            ),
            CustomInfoWindow(
              controller: _customInfoWindowController,
              height: 140,
              width: 230,
              offset: 60,
            ),
          ],
        );
      },
    );
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
}

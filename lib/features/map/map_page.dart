import 'dart:async';
import 'dart:io';

import 'package:custom_info_window/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../app/session/session_controller.dart';
import '../../core/logging/app_logger.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/capsule.dart';
import '../../data/models/geo_position.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/location_service.dart';
import '../../shared/widgets/popup/popup_notification_service.dart';
import '../../shared/widgets/later_loading_bar.dart';
import '../settings/device_settings_store.dart';
import 'current_location.dart';
import 'map_controller.dart';
import 'map_focus.dart';
import 'widgets/capsule_info_panel.dart';
import 'widgets/capsule_preview_card.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MapController(
        capsules: context.read<CapsuleRepository>(),
        location: context.read<LocationService>(),
        currentLocation: context.read<CurrentLocation>(),
        session: context.read<SessionController>(),
      )..start(),
      child: const _MapView(),
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

class _MapViewState extends State<_MapView> {
  final _mapController = Completer<GoogleMapController>();
  final _infoWindow = CustomInfoWindowController();
  late final MapFocus _focus;
  bool _reportedLocationProblem = false;

  /// Cloud-based map styles (Google Cloud Console "Map Management").
  static final _mapId = Platform.isAndroid
      ? '12b4f975aba292b65ac044ea'
      : '12b4f975aba292b627a4b587';

  @override
  void initState() {
    super.initState();
    _focus = context.read<MapFocus>()..addListener(_onFocusRequested);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusRequested);
    _infoWindow.dispose();
    super.dispose();
  }

  void _onFocusRequested() {
    if (_focus.pending == null) return;
    unawaited(_showFocusedCapsule());
  }

  /// Moves to a capsule requested from the history list or a notification.
  /// Waits for the map to exist, so requests made before it was built are
  /// not lost.
  Future<void> _showFocusedCapsule() async {
    final controller = await _mapController.future;
    final capsule = _focus.take();
    final location = capsule?.location;
    if (capsule == null || location == null || !mounted) return;
    _infoWindow.hideInfoWindow?.call();
    final target = LatLng(location.latitude, location.longitude);
    AppLogger.debug('Map focus: ${capsule.id}');
    await controller.animateCamera(CameraUpdate.newLatLngZoom(target, 18));
    AppLogger.debug('Map focus: camera moved');
    if (!mounted) return;
    _infoWindow.addInfoWindow?.call(_infoPanel(capsule), target);
  }

  Widget _infoPanel(Capsule capsule) => CapsuleInfoPanel(
    capsule: capsule,
    onMoreInfo: () => showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: CapsulePreviewCard(
          capsule: capsule,
          // Back to the capsule's place on the map.
          onPlaceTap: () {
            Navigator.of(dialogContext).pop();
            _focus.focus(capsule);
          },
        ),
      ),
    ),
  );

  void _reportLocationProblem(MapController map) {
    if (_reportedLocationProblem || !map.usedFallbackCamera) return;
    _reportedLocationProblem = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      PopupNotificationService.showError(
        context: context,
        message: switch (map.availability) {
          LocationAvailability.serviceDisabled =>
            'Turn on location to see capsules near you',
          LocationAvailability.denied || LocationAvailability.deniedForever =>
            'Allow location access to see capsules near you',
          LocationAvailability.available => 'We could not detect your location',
        },
        position: NotificationPosition.top,
      );
    });
  }

  Set<Marker> _markers(MapController map) {
    final icons = map.icons!;
    final markers = <Marker>{};
    final me = map.myPosition;
    if (me != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('_currentLocation'),
          icon: icons.user,
          position: LatLng(me.latitude, me.longitude),
        ),
      );
    }
    if (!map.showMarkers) return markers;
    for (final capsule in map.visibleCapsules) {
      final location = capsule.location!;
      final position = LatLng(location.latitude, location.longitude);
      markers.add(
        Marker(
          markerId: MarkerId(capsule.id),
          position: position,
          icon: icons.forColor(capsule.color),
          onTap: () =>
              _infoWindow.addInfoWindow?.call(_infoPanel(capsule), position),
        ),
      );
    }
    return markers;
  }

  /// The native heatmap throws on an empty point list (BUG-048), so the
  /// layer is only added when there is something to show.
  Set<Heatmap> _heatmaps(MapController map) {
    final points = [
      for (final c in map.visibleCapsules)
        WeightedLatLng(
          LatLng(c.location!.latitude, c.location!.longitude),
          weight: 1.0,
        ),
    ];
    if (points.isEmpty) return const {};
    return {
      Heatmap(
        heatmapId: const HeatmapId('capsules_heatmap'),
        data: points,
        radius: const HeatmapRadius.fromPixels(50),
        gradient: const HeatmapGradient([
          HeatmapGradientColor(AppColors.heatmapLow, 0.2),
          HeatmapGradientColor(AppColors.heatmapMid, 0.5),
          HeatmapGradientColor(AppColors.heatmapHigh, 1.0),
        ]),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapController>();
    final look = context.select<DeviceSettingsStore, MapLook>((s) => s.mapLook);
    if (map.state == MapLoadState.loading) {
      return const Center(child: LaterLoadingBar(width: 150, height: 150));
    }
    _reportLocationProblem(map);

    final screen = MediaQuery.sizeOf(context);
    final start = map.initialCamera;
    return Stack(
      children: [
        GoogleMap(
          mapId: _mapId,
          mapType: switch (look) {
            MapLook.standard => MapType.normal,
            MapLook.satellite => MapType.satellite,
            MapLook.hybrid => MapType.hybrid,
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(start.latitude, start.longitude),
            zoom: map.initialCameraZoom,
          ),
          onMapCreated: (controller) {
            _infoWindow.googleMapController = controller;
            if (!_mapController.isCompleted) {
              _mapController.complete(controller);
            }
            if (_focus.pending != null) unawaited(_showFocusedCapsule());
          },
          markers: _markers(map),
          heatmaps: _heatmaps(map),
          onTap: (_) => _infoWindow.hideInfoWindow?.call(),
          onCameraMove: (position) {
            _infoWindow.onCameraMove?.call();
            map.onCameraMove(position.zoom);
          },
          onCameraIdle: () async {
            final controller = await _mapController.future;
            final bounds = await controller.getVisibleRegion();
            final center = GeoPosition(
              (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
              (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
            );
            map.onCameraIdle(center, await controller.getZoomLevel());
          },
        ),
        CustomInfoWindow(
          controller: _infoWindow,
          height: (screen.height * 0.171).clamp(
            CapsuleInfoPanel.minHeight,
            double.infinity,
          ),
          width: screen.width * 0.58,
          offset: 60,
        ),
      ],
    );
  }
}

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/capsule.dart';
import '../cluster_icons.dart';
import '../map_controller.dart';
import '../map_stats.dart';
import '../marker_icons.dart';
import 'map_zoom_visuals.dart';

/// The map drawn by MapLibre (Spike B, docs/map/DECISION.md): the heat, the
/// bubbles and the pins are layers of the map itself, on the GPU, their look a
/// function of the zoom the map evaluates every frame, so a pinch changes
/// them continuously and nothing is sent from Flutter while it lasts.
class MapLibreMapView extends StatefulWidget {
  const MapLibreMapView({super.key});

  /// Free vector tiles for development (OpenFreeMap, no key). The production
  /// source is the owner's decision (DECISION.md).
  static const lightStyle = 'https://tiles.openfreemap.org/styles/positron';

  @override
  State<MapLibreMapView> createState() => _MapLibreMapViewState();
}

/// For tuning on the phone (debug): start at this zoom.
final double? _debugZoom = double.tryParse(
  const String.fromEnvironment('MAP_START_ZOOM'),
);

class _MapLibreMapViewState extends State<MapLibreMapView> {
  ml.MapLibreMapController? _controller;
  bool _styled = false;
  int? _dataVersion;
  int _pointers = 0;
  bool _moving = false;

  @override
  void initState() {
    super.initState();
    // A TextureView composed by Flutter (TLHC): the default SurfaceView made
    // Flutter fall back to hybrid composition, its frames 3x slower to draw.
    ml.MapLibreMap.useHybridComposition = true;
    MapStats.instance.watchFrames();
  }

  void _active() => MapStats.instance.active.value = _pointers > 0 || _moving;

  Future<void> _onStyleLoaded() async {
    final c = _controller;
    if (c == null) return;
    final map = context.read<MapController>();
    final ratio = MediaQuery.devicePixelRatioOf(context);
    await _addImages(c, ratio);
    await c.addSource(
      'capsules',
      ml.GeojsonSourceProperties(
        data: _features(map.visibleCapsules),
        cluster: true,
        clusterRadius: 48,
        clusterMaxZoom: 17,
      ),
    );
    await c.addSource(
      'capsules_heat',
      ml.GeojsonSourceProperties(data: _features(map.heatCapsules)),
    );
    await c.addHeatmapLayer(
      'capsules_heat',
      'heat',
      ml.HeatmapLayerProperties(
        heatmapWeight: 1,
        heatmapIntensity: const [
          'interpolate',
          ['linear'],
          ['zoom'],
          3,
          0.5,
          6,
          0.22,
          9,
          0.3,
          11,
          0.27,
          12,
          0.32,
        ],
        heatmapRadius: MapZoomVisuals.heatRadiusExpression(),
        heatmapOpacity: MapZoomVisuals.heatOpacityExpression(),
        heatmapColor: const [
          'interpolate',
          ['linear'],
          ['heatmap-density'],
          0,
          'rgba(33,150,243,0)',
          0.02,
          'rgba(33,150,243,0.12)',
          0.1,
          'rgba(86,201,46,0.22)',
          0.4,
          'rgba(255,217,0,0.29)',
          0.8,
          'rgba(255,152,0,0.35)',
        ],
      ),
      maxzoom: MapZoomVisuals.heatTo + 0.1,
    );
    final opacity = MapZoomVisuals.markerOpacityExpression();
    await c.addSymbolLayer(
      'capsules',
      'pins',
      ml.SymbolLayerProperties(
        iconImage: const [
          'concat',
          'pin_',
          ['get', 'color'],
        ],
        iconAnchor: 'bottom',
        iconSize: 1,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: opacity,
      ),
      filter: const [
        '!',
        ['has', 'point_count'],
      ],
      enableInteraction: false,
    );
    await c.addSymbolLayer(
      'capsules',
      'bubbles',
      ml.SymbolLayerProperties(
        iconImage: const [
          'concat',
          'bubble_',
          [
            'case',
            [
              '>',
              ['get', 'point_count'],
              99,
            ],
            '99+',
            [
              'to-string',
              ['get', 'point_count'],
            ],
          ],
        ],
        iconSize: 1,
        iconAllowOverlap: true,
        iconIgnorePlacement: true,
        iconOpacity: opacity,
      ),
      filter: const ['has', 'point_count'],
      enableInteraction: false,
    );
    _dataVersion = map.capsulesVersion;
    if (mounted) setState(() => _styled = true);
    if (_debugZoom != null) unawaited(_tuningCycle(c));
  }

  /// Tuning on the phone (debug, MAP_START_ZOOM): zoom 11, 9 and 6, five
  /// seconds each, over the seed's city.
  Future<void> _tuningCycle(ml.MapLibreMapController c) async {
    for (final zoom in const [11.0, 9.0, 6.0]) {
      await c.moveCamera(
        ml.CameraUpdate.newLatLngZoom(const ml.LatLng(52.2297, 21.0122), zoom),
      );
      await Future<void>.delayed(const Duration(seconds: 10));
    }
  }

  Future<void> _addImages(ml.MapLibreMapController c, double ratio) async {
    for (final color in CapsuleColor.values) {
      final image = MarkerIcons.pinPicture(color);
      if (image == null) continue;
      await c.addImage('pin_${color.name}', await _png(image));
    }
    for (var n = 2; n <= 100; n++) {
      await ClusterIcons.forCount(n, ratio);
      final picture = ClusterIcons.picture(n, ratio);
      if (picture == null) continue;
      await c.addImage(
        'bubble_${ClusterIcons.label(n)}',
        await _png(picture.$1),
      );
    }
  }

  static Future<Uint8List> _png(ui.Image image) async =>
      (await image.toByteData(
        format: ui.ImageByteFormat.png,
      ))!.buffer.asUint8List();

  static Map<String, dynamic> _features(Iterable<Capsule> capsules) => {
    'type': 'FeatureCollection',
    'features': [
      for (final c in capsules)
        if (c.location case final at?)
          {
            'type': 'Feature',
            'id': c.id,
            'properties': {'id': c.id, 'color': c.color.name},
            'geometry': {
              'type': 'Point',
              'coordinates': [at.longitude, at.latitude],
            },
          },
    ],
  };

  /// New capsules: the sources get them (the map regroups on its own).
  void _syncData(MapController map) {
    final c = _controller;
    if (!_styled || c == null || _dataVersion == map.capsulesVersion) return;
    _dataVersion = map.capsulesVersion;
    unawaited(c.setGeoJsonSource('capsules', _features(map.visibleCapsules)));
    unawaited(c.setGeoJsonSource('capsules_heat', _features(map.heatCapsules)));
  }

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapController>();
    if (map.state == MapLoadState.loading || map.icons == null) {
      return const ColoredBox(color: AppColors.onAccent);
    }
    _syncData(map);
    final start = map.initialCamera;
    return Stack(
      children: [
        Listener(
          onPointerDown: (_) {
            if (_pointers++ == 0) MapStats.instance.gestureStarted();
            _active();
          },
          onPointerUp: (_) {
            _pointers--;
            _active();
          },
          onPointerCancel: (_) {
            _pointers--;
            _active();
          },
          child: ml.MapLibreMap(
            styleString: MapLibreMapView.lightStyle,
            initialCameraPosition: ml.CameraPosition(
              target: ml.LatLng(start.latitude, start.longitude),
              zoom: _debugZoom ?? map.initialCameraZoom,
            ),
            trackCameraPosition: true,
            compassEnabled: false,
            tiltGesturesEnabled: false,
            annotationOrder: const [],
            attributionButtonPosition: ml.AttributionButtonPosition.bottomLeft,
            onMapCreated: (c) {
              _controller = c;
              if (MapStats.enabled) {
                MapStats.instance.moveCamera = (target, zoom) async {
                  await c.moveCamera(
                    ml.CameraUpdate.newLatLngZoom(
                      ml.LatLng(target.latitude, target.longitude),
                      zoom,
                    ),
                  );
                };
              }
            },
            onStyleLoadedCallback: () => unawaited(_onStyleLoaded()),
            onCameraMove: (_) {
              MapStats.instance.cameraMoved();
              if (!_moving) {
                _moving = true;
                _active();
              }
            },
            onCameraIdle: () {
              MapStats.instance.cameraIdle();
              _moving = false;
              _active();
              if (_pointers == 0) MapStats.instance.gestureEnded();
            },
          ),
        ),
        if (MapStats.harness)
          const Positioned(top: 0, left: 0, child: MapHarnessStrip()),
      ],
    );
  }
}

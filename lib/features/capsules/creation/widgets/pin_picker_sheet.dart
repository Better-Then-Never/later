import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:provider/provider.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/config/feature_flags.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/geo_position.dart';
import '../../../../shared/widgets/app_sheets.dart';
import '../../../../shared/widgets/buttons/default_green_button.dart';
import '../../../map/map_styles.dart';
import '../../../settings/device_settings_store.dart';

/// Fine-tunes where a capsule goes (B4): a map under a fixed pin, moved by
/// dragging the map, at most [radiusMeters] from where the phone is (the
/// places a user has been count for the Explorer achievement). Drawn by
/// MapLibre like the map page ([FeatureFlags.mapLibre]), else Google Maps.
class PinPickerSheet extends StatefulWidget {
  const PinPickerSheet({
    super.key,
    required this.here,
    required this.pinAsset,
    this.start,
    this.radiusMeters = 1000,
  });

  /// Where the phone is.
  final GeoPosition here;

  /// The spot chosen so far (the phone's place when not moved yet).
  final GeoPosition? start;
  final String pinAsset;
  final double radiusMeters;

  /// The spot chosen, or null when the sheet is dismissed.
  static Future<GeoPosition?> show(
    BuildContext context, {
    required GeoPosition here,
    required String pinAsset,
    GeoPosition? start,
  }) => showEdgeSheet<GeoPosition>(
    context,
    (_) => PinPickerSheet(here: here, start: start, pinAsset: pinAsset),
  );

  /// [spot] pulled back onto the circle of [radius] metres around [here].
  static GeoPosition clamp(GeoPosition here, GeoPosition spot, double radius) {
    final d = Geolocator.distanceBetween(
      here.latitude,
      here.longitude,
      spot.latitude,
      spot.longitude,
    );
    if (d <= radius) return spot;
    final k = radius / d;
    return GeoPosition(
      here.latitude + (spot.latitude - here.latitude) * k,
      here.longitude + (spot.longitude - here.longitude) * k,
    );
  }

  /// The circle of [radius] metres around [center] as a closed GeoJSON ring
  /// of [corners] corners: [longitude, latitude] pairs, the last the first.
  static List<List<double>> ring(
    GeoPosition center,
    double radius, {
    int corners = 256,
  }) {
    const earth = 6371008.8;
    final dLat = radius / earth * 180 / math.pi;
    final dLng = dLat / math.cos(center.latitude * math.pi / 180);
    return [
      for (var i = 0; i <= corners; i++)
        [
          center.longitude +
              dLng * math.sin(2 * math.pi * (i % corners) / corners),
          center.latitude +
              dLat * math.cos(2 * math.pi * (i % corners) / corners),
        ],
    ];
  }

  @override
  State<PinPickerSheet> createState() => _PinPickerSheetState();
}

class _PinPickerSheetState extends State<PinPickerSheet> {
  final _google = Completer<GoogleMapController>();
  final _libre = Completer<ml.MapLibreMapController>();
  late GeoPosition _spot = widget.start ?? widget.here;
  bool _tooFar = false;

  /// The map takes every touch that starts on it: otherwise the sheet's
  /// drag-to-close wins every vertical drag and the pin cannot move.
  static const _mapGestures = <Factory<OneSequenceGestureRecognizer>>{
    Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
  };

  @override
  void initState() {
    super.initState();
    // A TextureView composed by Flutter, as on the map page: it clips to the
    // rounded corners and draws as fast as the rest of the sheet.
    if (FeatureFlags.mapLibre) ml.MapLibreMap.useHybridComposition = true;
  }

  LatLng _latLng(GeoPosition p) => LatLng(p.latitude, p.longitude);

  void _onMove(double latitude, double longitude) {
    final spot = GeoPosition(latitude, longitude);
    final allowed = PinPickerSheet.clamp(
      widget.here,
      spot,
      widget.radiusMeters,
    );
    final tooFar = allowed != spot;
    if (tooFar != _tooFar) setState(() => _tooFar = tooFar);
    _spot = allowed;
  }

  Future<void> _onIdle() async {
    if (!_tooFar) return;
    // Back onto the edge of the circle.
    unawaited(HapticFeedback.lightImpact());
    await _moveTo(_spot);
    if (mounted) setState(() => _tooFar = false);
  }

  Future<void> _moveTo(GeoPosition p) async {
    if (FeatureFlags.mapLibre) {
      final map = await _libre.future;
      await map.animateCamera(
        ml.CameraUpdate.newLatLng(ml.LatLng(p.latitude, p.longitude)),
      );
    } else {
      final map = await _google.future;
      await map.animateCamera(CameraUpdate.newLatLng(_latLng(p)));
    }
  }

  /// The circle the pin may move in, under everything else on the map.
  Future<void> _addReach(Color color) async {
    final map = await _libre.future;
    await map.addGeoJsonSource('reach', {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': <String, dynamic>{},
          'geometry': {
            'type': 'Polygon',
            'coordinates': [
              PinPickerSheet.ring(widget.here, widget.radiusMeters),
            ],
          },
        },
      ],
    });
    final css = color.toHexStringRGB();
    await map.addFillLayer(
      'reach',
      'reach_fill',
      ml.FillLayerProperties(fillColor: css, fillOpacity: 0.08),
      enableInteraction: false,
    );
    await map.addLineLayer(
      'reach',
      'reach_line',
      ml.LineLayerProperties(lineColor: css, lineWidth: 2),
      enableInteraction: false,
    );
  }

  Widget _mapLibre(AppPalette palette) => ml.MapLibreMap(
    // The map page's style over OpenFreeMap tiles (docs/map/DECISION.md).
    styleString: palette.isDark ? AppMapStyles.dark : AppMapStyles.light,
    foregroundLoadColor: palette.isDark
        ? AppColors.mapGroundDark
        : AppColors.mapGroundLight,
    initialCameraPosition: ml.CameraPosition(
      target: ml.LatLng(_spot.latitude, _spot.longitude),
      zoom: 16,
    ),
    gestureRecognizers: _mapGestures,
    trackCameraPosition: true,
    compassEnabled: false,
    rotateGesturesEnabled: false,
    tiltGesturesEnabled: false,
    // OpenStreetMap's credit, as on the map page.
    attributionButtonPosition: ml.AttributionButtonPosition.bottomLeft,
    attributionButtonMargins: const math.Point(12, 12),
    onMapCreated: (c) {
      if (!_libre.isCompleted) _libre.complete(c);
    },
    onStyleLoadedCallback: () => unawaited(_addReach(palette.textMuted)),
    onCameraMove: (camera) =>
        _onMove(camera.target.latitude, camera.target.longitude),
    onCameraIdle: () => unawaited(_onIdle()),
  );

  Widget _googleMap(AppPalette palette, MapLook look) => GoogleMap(
    style: palette.isDark ? MapStyles.dark : MapStyles.light,
    mapType: switch (look) {
      MapLook.standard => MapType.normal,
      MapLook.satellite => MapType.satellite,
      MapLook.hybrid => MapType.hybrid,
    },
    initialCameraPosition: CameraPosition(target: _latLng(_spot), zoom: 16),
    gestureRecognizers: _mapGestures,
    zoomControlsEnabled: false,
    mapToolbarEnabled: false,
    compassEnabled: false,
    myLocationButtonEnabled: false,
    rotateGesturesEnabled: false,
    tiltGesturesEnabled: false,
    circles: {
      Circle(
        circleId: const CircleId('reach'),
        center: _latLng(widget.here),
        radius: widget.radiusMeters,
        strokeWidth: 2,
        strokeColor: palette.textMuted,
        fillColor: palette.textMuted.withValues(alpha: 0.08),
      ),
    },
    onMapCreated: (c) {
      if (!_google.isCompleted) _google.complete(c);
    },
    onCameraMove: (camera) =>
        _onMove(camera.target.latitude, camera.target.longitude),
    onCameraIdle: () => unawaited(_onIdle()),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final height = MediaQuery.sizeOf(context).height;
    return Container(
      height: height * 0.75,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSheets.radius),
        ),
      ),
      child: Column(
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: Text(
              l10n.capsulesPinTitle,
              style: AppTextStyles.pageTitle(context).copyWith(fontSize: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              _tooFar ? l10n.capsulesPinTooFar : l10n.capsulesPinHint,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: palette.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSheets.radius),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // MapLibre has no satellite look: Settings hides the
                  // choice, so one made earlier does not stick here.
                  if (FeatureFlags.mapLibre)
                    _mapLibre(palette)
                  else
                    _googleMap(
                      palette,
                      context.select<DeviceSettingsStore, MapLook>(
                        (s) => s.mapLook,
                      ),
                    ),
                  // The pin's tip sits on the middle of the map.
                  IgnorePointer(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 44),
                      child: Image.asset(widget.pinAsset, width: 44),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Semantics(
                      button: true,
                      label: l10n.capsulesPinBack,
                      child: GestureDetector(
                        onTap: () => unawaited(_moveTo(widget.here)),
                        child: Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: palette.surface,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(AppIcons.mapPinUser),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(48, 12, 48, 12),
              child: DefaultGreenButton(
                onTap: () => Navigator.of(context).pop(_spot),
                text: l10n.capsulesPinUse,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

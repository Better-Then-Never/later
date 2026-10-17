import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../data/models/geo_position.dart';
import '../../../../shared/widgets/app_sheets.dart';
import '../../../../shared/widgets/buttons/default_green_button.dart';
import '../../../map/map_styles.dart';
import '../../../settings/device_settings_store.dart';

/// Fine-tunes where a capsule goes (B4): a map under a fixed pin, moved by
/// dragging the map, at most [radiusMeters] from where the phone is (the
/// places a user has been count for the Explorer achievement).
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

  @override
  State<PinPickerSheet> createState() => _PinPickerSheetState();
}

class _PinPickerSheetState extends State<PinPickerSheet> {
  final _map = Completer<GoogleMapController>();
  late GeoPosition _spot = widget.start ?? widget.here;
  bool _tooFar = false;

  LatLng _latLng(GeoPosition p) => LatLng(p.latitude, p.longitude);

  void _onMove(CameraPosition camera) {
    final spot = GeoPosition(camera.target.latitude, camera.target.longitude);
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
    final map = await _map.future;
    await map.animateCamera(CameraUpdate.newLatLng(_latLng(_spot)));
    if (mounted) setState(() => _tooFar = false);
  }

  Future<void> _backHere() async {
    final map = await _map.future;
    await map.animateCamera(CameraUpdate.newLatLng(_latLng(widget.here)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final palette = context.palette;
    final look = context.select<DeviceSettingsStore, MapLook>((s) => s.mapLook);
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
                  GoogleMap(
                    style: palette.isDark ? MapStyles.dark : MapStyles.light,
                    mapType: switch (look) {
                      MapLook.standard => MapType.normal,
                      MapLook.satellite => MapType.satellite,
                      MapLook.hybrid => MapType.hybrid,
                    },
                    initialCameraPosition: CameraPosition(
                      target: _latLng(_spot),
                      zoom: 16,
                    ),
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
                      if (!_map.isCompleted) _map.complete(c);
                    },
                    onCameraMove: _onMove,
                    onCameraIdle: () => unawaited(_onIdle()),
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
                        onTap: _backHere,
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

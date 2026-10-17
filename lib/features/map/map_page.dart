import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../app/router/app_routes.dart';
import '../../app/session/session_controller.dart';
import '../../app/shell/selected_page.dart';
import '../../core/l10n/l10n.dart';
import '../../core/logging/app_logger.dart';
import '../../app/shell/navbar_widget.dart';
import '../../core/assets/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_palette.dart';
import '../../data/models/capsule.dart';
import '../../data/models/geo_position.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/location_service.dart';
import '../../data/services/preferences_store.dart';
import '../../shared/motion/app_motion_widgets.dart';
import '../../shared/widgets/popup/popup_notification_service.dart';
import '../../shared/widgets/later_loading_bar.dart';
import '../settings/device_settings_store.dart';
import 'current_location.dart';
import 'map_clusters.dart';
import 'map_controller.dart';
import 'map_focus.dart';
import 'map_styles.dart';
import '../history/own_capsules_store.dart';
import 'widgets/capsule_info_panel.dart';
import 'widgets/first_capsule_hint.dart';
import '../capsules/social/capsule_detail_dialog.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Read here: a provider's create callback must not depend on the theme.
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ChangeNotifierProvider(
      create: (context) =>
          MapController(
              capsules: context.read<CapsuleRepository>(),
              location: context.read<LocationService>(),
              currentLocation: context.read<CurrentLocation>(),
              session: context.read<SessionController>(),
            )
            ..setDarkIcons(dark)
            ..start(),
      child: const _MapView(),
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

/// Round button above the navigation bar that brings the map to the user,
/// drawn with the map's own "you" figure.
class _MyLocationButton extends StatelessWidget {
  const _MyLocationButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: context.l10n.mapMyLocation,
      child: AppPressable(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
              border: palette.isDark
                  ? Border.all(color: palette.cardBorder)
                  : null,
              boxShadow: AppShadows.raised(context),
            ),
            child: Image.asset(AppIcons.mapPinUser),
          ),
        ),
      ),
    );
  }
}

class _MapViewState extends State<_MapView> {
  final _mapController = Completer<GoogleMapController>();

  /// The theme the marker icons were drawn for. A theme switch restyles the
  /// map in place (two local styles, no map ID) and redraws the icons.
  bool? _builtDark;
  CameraPosition? _lastCamera;

  /// The capsule whose card is open (F-17: our own card replaces the
  /// info-window package, which re-opened itself after being closed).
  Capsule? _selected;
  late final MapFocus _focus;
  bool _reportedLocationProblem = false;

  /// "Leave your first capsule" was closed on this phone for this account
  /// (hidden until that is known).
  bool _hintClosed = true;
  static const _hintKey = 'first_capsule_hint';

  @override
  void initState() {
    super.initState();
    _focus = context.read<MapFocus>()..addListener(_onFocusRequested);
    selectedPageNotifier.addListener(_onTabChanged);
    unawaited(_loadHint());
  }

  Future<void> _loadHint() async {
    final uid = context.read<SessionController>().uid;
    if (uid == null) return;
    final closed =
        await context.read<PreferencesStore>().string(uid, _hintKey) ==
        'closed';
    if (mounted && !closed) setState(() => _hintClosed = false);
  }

  void _closeHint() {
    setState(() => _hintClosed = true);
    final uid = context.read<SessionController>().uid;
    if (uid != null) {
      unawaited(
        context.read<PreferencesStore>().setString(uid, _hintKey, 'closed'),
      );
    }
  }

  /// Leaving the map tab closes the card.
  void _onTabChanged() {
    if (selectedPageNotifier.value != AppTabs.map) _select(null);
  }

  void _select(Capsule? capsule) {
    if (!mounted || capsule?.id == _selected?.id) return;
    setState(() => _selected = capsule);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusRequested);
    selectedPageNotifier.removeListener(_onTabChanged);
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
    _select(null);
    final target = LatLng(location.latitude, location.longitude);
    AppLogger.debug('Map focus: ${capsule.id}');
    await controller.animateCamera(CameraUpdate.newLatLngZoom(target, 18));
    AppLogger.debug('Map focus: camera moved');
    _select(capsule);
  }

  /// A tap on a numbered bubble: the camera moves in on its capsules.
  Future<void> _zoomTo(MapItem cluster) async {
    final controller = await _mapController.future;
    final b = cluster.bounds!;
    if ((b.north - b.south).abs() < 1e-4 && (b.east - b.west).abs() < 1e-4) {
      // All in one spot: closer, around it.
      final zoom = await controller.getZoomLevel();
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(cluster.at.latitude, cluster.at.longitude),
          zoom + 2,
        ),
      );
      return;
    }
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(b.south, b.west),
          northeast: LatLng(b.north, b.east),
        ),
        64,
      ),
    );
  }

  Widget _infoPanel(Capsule capsule) => CapsuleInfoPanel(
    capsule: capsule,
    onMoreInfo: () => CapsuleDetailDialog.show(
      context,
      capsule,
      // Back to the capsule's place on the map.
      onPlaceTap: () => _focus.focus(capsule),
    ),
  );

  Future<void> _goToMe(MapController map) async {
    unawaited(HapticFeedback.selectionClick());
    final position = await map.locateMe();
    if (!mounted) return;
    if (position == null) {
      final l10n = context.l10n;
      final availability = map.availability;
      PopupNotificationService.showError(
        context: context,
        message: switch (availability) {
          LocationAvailability.serviceDisabled => l10n.mapLocationServiceOff,
          LocationAvailability.denied ||
          LocationAvailability.deniedForever => l10n.mapLocationDenied,
          LocationAvailability.available => l10n.mapLocationUnknown,
        },
        position: NotificationPosition.top,
      );
      // Only the system settings can turn these back on.
      if (availability == LocationAvailability.deniedForever) {
        unawaited(Geolocator.openAppSettings());
      } else if (availability == LocationAvailability.serviceDisabled) {
        unawaited(context.read<LocationService>().openSettings());
      }
      return;
    }
    final controller = await _mapController.future;
    final zoom = await controller.getZoomLevel();
    await controller.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        zoom < 14 ? 15 : zoom,
      ),
    );
  }

  void _reportLocationProblem(MapController map) {
    if (_reportedLocationProblem || !map.usedFallbackCamera) return;
    _reportedLocationProblem = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = context.l10n;
      PopupNotificationService.showError(
        context: context,
        message: switch (map.availability) {
          LocationAvailability.serviceDisabled => l10n.mapLocationServiceOff,
          LocationAvailability.denied ||
          LocationAvailability.deniedForever => l10n.mapLocationDenied,
          LocationAvailability.available => l10n.mapLocationUnknown,
        },
        position: NotificationPosition.top,
      );
    });
  }

  // Marker and heatmap sets are rebuilt only when the capsules, the icons or
  // the zoom band change (F-10): a new Marker carries a new tap closure, so
  // rebuilding them on every position update or frame made the plugin send
  // every marker to the native map again.
  Object? _capsuleMarkersKey;
  Set<Marker> _capsuleMarkers = const {};
  Object? _heatmapsKey;
  Set<Heatmap> _heatmapsCache = const {};
  GeoPosition? _userMarkerAt;
  Marker? _userMarker;

  Set<Marker> _markers(MapController map) {
    final icons = map.icons!;
    final me = map.myPosition;
    if (me != _userMarkerAt || _userMarker?.icon != icons.user) {
      _userMarkerAt = me;
      _userMarker = me == null
          ? null
          : Marker(
              markerId: const MarkerId('_currentLocation'),
              icon: icons.user,
              position: LatLng(me.latitude, me.longitude),
            );
    }
    // Only what is on screen, clustered (MapController.items): every marker
    // update runs on Android's main thread.
    final key = (map.itemsVersion, icons.capsulePins);
    if (key != _capsuleMarkersKey) {
      _capsuleMarkersKey = key;
      _capsuleMarkers = {
        for (final item in map.items)
          if (item.capsule case final capsule?)
            Marker(
              markerId: MarkerId(capsule.id),
              position: LatLng(
                capsule.location!.latitude,
                capsule.location!.longitude,
              ),
              icon: icons.forColor(capsule.color),
              onTap: () => _select(capsule),
            )
          else
            Marker(
              markerId: MarkerId(item.id),
              position: LatLng(item.at.latitude, item.at.longitude),
              icon:
                  map.clusterIcon(item.count) ?? BitmapDescriptor.defaultMarker,
              anchor: const Offset(0.5, 0.5),
              zIndexInt: 1,
              onTap: () => unawaited(_zoomTo(item)),
            ),
      };
    }
    final user = _userMarker;
    return user == null ? _capsuleMarkers : {user, ..._capsuleMarkers};
  }

  /// The native heatmap throws on an empty point list (BUG-048), so the
  /// layer is only added when there is something to show.
  Set<Heatmap> _heatmaps(MapController map) {
    final key = (map.capsulesVersion, map.showMarkers);
    if (_heatmapsKey == key) return _heatmapsCache;
    _heatmapsKey = key;
    // Zoomed in the markers say where capsules are; the glow is only the
    // overview from afar (F-16).
    return _heatmapsCache = map.showMarkers ? const {} : _buildHeatmaps(map);
  }

  Set<Heatmap> _buildHeatmaps(MapController map) {
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
        radius: const HeatmapRadius.fromPixels(40),
        opacity: 0.7,
        gradient: const HeatmapGradient([
          HeatmapGradientColor(AppColors.heatmapLow, 0.2),
          HeatmapGradientColor(AppColors.heatmapHigh, 1.0),
        ]),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapController>()
      ..pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final look = context.select<DeviceSettingsStore, MapLook>((s) => s.mapLook);
    if (map.state == MapLoadState.loading) {
      return const Center(child: LaterLoadingBar(width: 150, height: 150));
    }
    _reportLocationProblem(map);

    final start = map.initialCamera;
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_builtDark != null && _builtDark != dark) {
      unawaited(map.setDarkIcons(dark));
    }
    _builtDark = dark;
    final selected = _selected;
    final bottom = NavbarWidget.coveredHeight(context) + 12;
    final cardHeight = CapsuleInfoPanel.heightFor(context);
    final motion = AppMotion.of(context, AppMotion.emphasized);
    // A new user: nothing of theirs yet (a capsule waiting to upload counts).
    final noCapsules = context.select<OwnCapsulesStore, bool>(
      (s) => s.isLoaded && s.capsules.isEmpty,
    );
    final showHint = selected == null && noCapsules && !_hintClosed;
    // What floats above the bar: the capsule card or the hint.
    final raised = selected != null
        ? cardHeight + 12
        : showHint
        ? FirstCapsuleHint.heightFor(context) + 12
        : 0.0;
    return PopScope(
      // Back closes the card first.
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(null);
      },
      child: Stack(
        children: [
          GoogleMap(
            style: dark ? MapStyles.dark : MapStyles.light,
            // The Google logo stays visible above the floating navigation
            // bar, above the capsule card while it is open, and below the
            // status bar: it is never covered (F-12, F-14). The zoom buttons
            // were hidden under the bar (pinch zooms).
            padding: EdgeInsets.only(
              top: MediaQuery.viewPaddingOf(context).top,
              bottom: NavbarWidget.coveredHeight(context) + 4 + raised,
            ),
            zoomControlsEnabled: false,
            // The capsule card replaces Google's marker toolbar.
            mapToolbarEnabled: false,
            mapType: switch (look) {
              MapLook.standard => MapType.normal,
              MapLook.satellite => MapType.satellite,
              MapLook.hybrid => MapType.hybrid,
            },
            initialCameraPosition:
                _lastCamera ??
                CameraPosition(
                  target: LatLng(start.latitude, start.longitude),
                  zoom: map.initialCameraZoom,
                ),
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
              if (_focus.pending != null) unawaited(_showFocusedCapsule());
            },
            markers: _markers(map),
            heatmaps: _heatmaps(map),
            onTap: (_) => _select(null),
            onCameraMove: (position) {
              _lastCamera = position;
              // Zoomed out past the markers: their card goes too.
              if (position.zoom < MapController.markerZoomThreshold) {
                _select(null);
              }
              map.onCameraMove(position.zoom);
            },
            onCameraIdle: () async {
              final controller = await _mapController.future;
              try {
                final bounds = await controller.getVisibleRegion();
                final center = GeoPosition(
                  (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                  (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
                );
                map.onCameraIdle(
                  center,
                  await controller.getZoomLevel(),
                  view: GeoBounds(
                    south: bounds.southwest.latitude,
                    west: bounds.southwest.longitude,
                    north: bounds.northeast.latitude,
                    east: bounds.northeast.longitude,
                  ),
                );
              } on StateError {
                // The map went away (the tab was rebuilt) while this ran.
              }
            },
          ),
          AnimatedPositioned(
            duration: motion,
            curve: AppMotion.emphasizedCurve,
            right: 16,
            // Moves up while a capsule card (or the hint) is shown.
            bottom: bottom + raised,
            child: _MyLocationButton(onTap: () => _goToMe(map)),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: bottom,
            child: AnimatedSwitcher(
              duration: motion,
              switchInCurve: AppMotion.emphasizedCurve,
              switchOutCurve: AppMotion.exit,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: selected == null
                  ? showHint
                        ? Center(
                            key: const ValueKey('hint'),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 440),
                              child: FirstCapsuleHint(
                                onTap: () => AppRoutes.toCamera(context),
                                onClose: _closeHint,
                              ),
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('none'),
                            width: double.infinity,
                          )
                  : GestureDetector(
                      key: ValueKey(selected.id),
                      // Swipe down to close.
                      onVerticalDragEnd: (details) {
                        if ((details.primaryVelocity ?? 0) > 150) _select(null);
                      },
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: SizedBox(
                            height: cardHeight,
                            child: _infoPanel(selected),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

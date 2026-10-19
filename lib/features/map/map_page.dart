import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' show Geolocator;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/scheduler.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
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
import '../../core/config/feature_flags.dart';
import 'map_stats.dart';
import 'capsule_heatmap.dart';
import 'map_viewport.dart';
import 'marker_choreography.dart';
import 'marker_icons.dart';
import 'cluster_icons.dart';
import 'map_projection.dart';
import 'selected_pin.dart';
import '../history/own_capsules_store.dart';
import 'widgets/capsule_info_panel.dart';
import 'widgets/first_capsule_hint.dart';
import 'widgets/map_compass.dart';
import '../capsules/social/capsule_detail_dialog.dart';
import 'widgets/map_filter_sheet.dart';
import 'widgets/selected_pin_overlay.dart';
import 'widgets/marker_choreography_overlay.dart';
import 'engine/map_zoom_visuals.dart';
import 'engine/maplibre_images.dart';
import 'engine/map_camera_memory.dart';
import 'engine/bubble_members.dart';
import '../achievements/streak_pill.dart';

part 'engine/maplibre_map_view.dart';

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
              prefs: context.read<PreferencesStore>(),
              groupsMarkers: !FeatureFlags.mapLibre,
            )
            ..setDarkIcons(dark)
            ..start(),
      child: FeatureFlags.mapLibre ? const MapLibreMapView() : const _MapView(),
    );
  }
}

class _MapView extends StatefulWidget {
  const _MapView();

  @override
  State<_MapView> createState() => _MapViewState();
}

/// Zoom in and out: one pill of two map-control-sized halves, the signs
/// drawn in the hand-drawn icons' rounded stroke (no icon font).
class _ZoomButtons extends StatelessWidget {
  const _ZoomButtons({required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget half(String label, VoidCallback onTap, {required bool plus}) =>
        Semantics(
          button: true,
          label: label,
          child: AppPressable(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: SizedBox.square(
                dimension: AppSizes.mapControl,
                child: CustomPaint(
                  painter: _SignPainter(plus: plus, color: palette.icon),
                ),
              ),
            ),
          ),
        );
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(AppSizes.mapControl / 2),
        border: palette.isDark ? Border.all(color: palette.cardBorder) : null,
        boxShadow: AppShadows.raised(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          half(context.l10n.mapZoomIn, onZoomIn, plus: true),
          Container(width: 24, height: 1, color: palette.divider),
          half(context.l10n.mapZoomOut, onZoomOut, plus: false),
        ],
      ),
    );
  }
}

class _SignPainter extends CustomPainter {
  const _SignPainter({required this.plus, required this.color});

  final bool plus;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    // The sign keeps its proportion to the button (9 at the old 52 dp).
    final arm = size.shortestSide * 0.17;
    canvas.drawLine(c - Offset(arm, 0), c + Offset(arm, 0), paint);
    if (plus) {
      canvas.drawLine(c - Offset(0, arm), c + Offset(0, arm), paint);
    }
  }

  @override
  bool shouldRepaint(_SignPainter old) =>
      old.plus != plus || old.color != color;
}

/// Round button above the navigation bar that brings the map to the user,
/// drawn with the map's own "you" figure.
/// Opens the map filter; a green dot while it leaves something out.
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});

  final int active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: active == 0 ? l10n.mapFilter : l10n.mapFilterActive(active),
      child: AppPressable(
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: AppSizes.mapControl,
                height: AppSizes.mapControl,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: palette.surface,
                  shape: BoxShape.circle,
                  border: palette.isDark
                      ? Border.all(color: palette.cardBorder)
                      : null,
                  boxShadow: AppShadows.raised(context),
                ),
                child: Image.asset(AppIcons.historyFilter),
              ),
              if (active > 0)
                Positioned(
                  right: 1,
                  top: 1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.brandGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyLocationButton extends StatelessWidget {
  const _MyLocationButton({required this.onTap});

  static const size = AppSizes.mapControl;

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
            width: size,
            height: size,
            padding: const EdgeInsets.all(8),
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

/// A floating pin: selected (up), landing, or down on its spot while its
/// native marker shows again.
enum _Float { up, landing, landed }

/// A pin floating over the map (M-02). While the map is still, Flutter draws
/// it ([SelectedPinOverlay]) and its native marker hides; while the map
/// moves, the map draws it, posed as the overlay left it ([SelectedPin.apply]):
/// the map reports its camera after drawing and in bursts, so an overlay
/// trails a moving map. Each hand-over waits until the map has drawn its side,
/// so the pin is never missing or doubled.
class _Floating {
  _Floating(this.capsule, {required bool still})
    : native = !still,
      drawn = still,
      running = still;

  final Capsule capsule;
  final motion = PinMotion();
  _Float phase = _Float.up;

  /// The map draws it, posed.
  bool native;

  /// The overlay is drawn (also while a hand-over is under way).
  bool drawn;

  /// The overlay's motion runs (the map is still and its own pin hidden).
  bool running;

  /// Counts hand-overs: a step left over from an earlier one does nothing.
  int turn = 0;
}

class _MapViewState extends State<_MapView> {
  final _mapController = Completer<GoogleMapController>();

  /// Which way the map is turned, in degrees (0 = north up); only the compass
  /// listens, so turning the map does not rebuild the page.
  final _bearing = ValueNotifier<double>(0);

  /// The theme the marker icons were drawn for. A theme switch restyles the
  /// map in place (two local styles, no map ID) and redraws the icons.
  bool? _builtDark;

  /// What the map shows: the floating pins follow it frame by frame (M-02)
  /// without rebuilding the page.
  final _viewport = MapViewport();
  EdgeInsets? _askedPadding;

  /// The capsule whose card is open (F-17: our own card replaces the
  /// info-window package, which re-opened itself after being closed).
  Capsule? _selected;

  /// The floating pins (M-02): the selected one, and any landing back on
  /// their spots after a deselection.
  final _floating = <String, _Floating>{};

  /// How capsules come onto the map and leave it (M-03, M-04): the map shows
  /// its markers once they have landed.
  final _choreography = MarkerChoreography();

  /// Far out, where capsules are, as heat (M-11).
  final _heatmap = CapsuleHeatmap();
  int? _heatmapVersion;
  int _choreographyVersion = 0;

  /// The first capsules wait until the map has drawn itself: they came in
  /// over a blank map before (the map cannot say when it has drawn; its
  /// first stop plus [_mapDraws] covers it), and their lists arrive in
  /// pieces meanwhile, which then come in together.
  static const _mapDraws = Duration(milliseconds: 450);
  DateTime? _firstStop;
  DateTime? _firstAsked;
  bool _firstShown = false;
  bool _choreographyDue = false;
  Timer? _firstShowTimer;

  /// Fingers on the map, and whether its camera moves: the floating pins are
  /// Flutter's only while neither.
  int _pointers = 0;
  bool _cameraMoving = false;
  bool get _still => _pointers == 0 && !_cameraMoving;

  /// For measuring: the map is moving or under a finger.
  void _activeChanged() => MapStats.instance.active.value = !_still;

  /// A camera move asked for (a button, a tapped pin) that has not started
  /// yet; if it never does, the map counts as still again.
  bool _moveStarted = false;
  Timer? _expectedMove;
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

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    unawaited(SelectedPinOverlay.precache(context));
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
    setState(() {
      if (_floating[_selected?.id] case final previous?) {
        previous
          ..phase = _Float.landing
          ..motion.land();
      }
      _selected = capsule;
      if (capsule == null) return;
      if (_floating[capsule.id] case final again?) {
        // Selected again while landing: it jumps again.
        again
          ..phase = _Float.up
          ..motion.jumpAgain();
      } else {
        _floating[capsule.id] = _Floating(capsule, still: _still);
      }
    });
  }

  /// A pin is down on its spot: its native marker shows again, and the
  /// overlay (which looks the same) stays over it until the map has drawn it.
  /// That marker changes, so it shows only once its bitmap has loaded again:
  /// the overlay waits a while (the map is still meanwhile).
  void _landed(String id) {
    final pin = _floating[id];
    if (!mounted || pin == null || pin.phase != _Float.landing) return;
    setState(() => pin.phase = _Float.landed);
    unawaited(
      _afterNativeMap(() {
        if (_floating[id]?.phase == _Float.landed) {
          setState(() => _floating.remove(id));
        }
      }, settle: const Duration(milliseconds: 250)),
    );
  }

  void _pointerDown(PointerDownEvent _) {
    if (_pointers == 0) MapStats.instance.gestureStarted();
    MapStats.instance.watchFrames();
    final wasStill = _still;
    _pointers++;
    _activeChanged();
    if (wasStill) _mapMoves();
  }

  void _pointerUp(PointerEvent _) {
    if (_pointers == 0) return;
    _pointers--;
    _activeChanged();
    if (_still) _mapStill();
  }

  void _cameraStarted() {
    _moveStarted = true;
    final wasStill = _still;
    _cameraMoving = true;
    _activeChanged();
    if (wasStill) _mapMoves();
  }

  void _cameraStopped() {
    _expectedMove?.cancel();
    _firstStop ??= DateTime.now();
    if (!_cameraMoving) return;
    _cameraMoving = false;
    _activeChanged();
    if (_still) _mapStill();
  }

  /// The camera is about to move (a button, a tapped pin): the map takes the
  /// pins first, so they never trail it. If it does not move after all, the
  /// map counts as still again.
  void _expectCameraMove() {
    _cameraStarted();
    _moveStarted = false;
    _expectedMove?.cancel();
    _expectedMove = Timer(const Duration(milliseconds: 600), () {
      if (!_moveStarted) _cameraStopped();
    });
  }

  /// A finger or the camera starts the map moving: the map takes the pins,
  /// posed as they are; their overlays go once it has drawn them.
  void _mapMoves() {
    if (!mounted) return;
    final handed = <_Floating>[];
    // Coming capsules land at once (sprites would trail a moving map), and
    // stand still until the map has drawn them.
    if (_choreography.active) {
      _choreographyVersion++;
      _actLanded(_choreography.finish());
    }
    setState(() {
      for (final pin in _floating.values) {
        pin
          ..turn += 1
          ..running = false;
        // A landed one is the map's already; its overlay goes by itself.
        if (pin.phase == _Float.landed) continue;
        pin.native = true;
        if (pin.drawn) handed.add(pin);
      }
    });
    for (final pin in handed) {
      final turn = pin.turn;
      // The map's posed pin is added: it shows once its bitmap has loaded.
      unawaited(
        _afterNativeMap(() {
          if (pin.turn == turn) setState(() => pin.drawn = false);
        }, settle: const Duration(milliseconds: 100)),
      );
    }
  }

  /// The map is still again: the overlays come back over the map's posed
  /// pins (they line up now), then those hide, then the motion goes on.
  void _mapStill() {
    // A finger gesture (and its fling) is over: its counts go to the log.
    MapStats.instance.gestureEnded();
    if (!mounted) return;
    final handed = <_Floating>[];
    setState(() {
      // A marker change that waited for the map to be still (_choreograph)
      // runs in this build.
      for (final pin in _floating.values) {
        pin.turn++;
        pin.drawn = true;
        if (pin.native) {
          handed.add(pin);
        } else {
          pin.running = true;
        }
      }
    });
    for (final pin in handed) {
      final turn = pin.turn;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || pin.turn != turn) return;
        setState(() => pin.native = false);
        unawaited(
          _afterNativeMap(() {
            if (pin.turn == turn) setState(() => pin.running = true);
          }),
        );
      });
    }
  }

  /// Completes once the native map has handled all that this frame sent it:
  /// it handles messages in order, so a question asked after them is
  /// answered after them. False when the map is gone.
  Future<bool> _nativeMapCaughtUp() {
    final done = Completer<bool>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final controller = await _mapController.future;
        await controller.getZoomLevel();
        done.complete(mounted);
      } catch (_) {
        done.complete(false);
      }
    });
    return done.future;
  }

  /// The map has the padding this frame asks for (MapViewport).
  Future<void> _confirmPadding() async {
    if (await _nativeMapCaughtUp()) _viewport.confirmed();
  }

  /// Runs [then] once the native map has handled and drawn all that this
  /// frame sent it: an added marker within a few frames; a changed one gets
  /// its bitmap again and needs longer ([settle]).
  Future<void> _afterNativeMap(
    VoidCallback then, {
    Duration settle = Duration.zero,
  }) async {
    if (!await _nativeMapCaughtUp()) return;
    for (var i = 0; i < 3; i++) {
      await WidgetsBinding.instance.endOfFrame;
    }
    if (settle > Duration.zero) await Future<void>.delayed(settle);
    if (mounted) then();
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusRequested);
    selectedPageNotifier.removeListener(_onTabChanged);
    _bearing.dispose();
    _viewport.dispose();
    _expectedMove?.cancel();
    _firstShowTimer?.cancel();
    _trickleTimer?.cancel();
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
    _expectCameraMove();
    await controller.animateCamera(CameraUpdate.newLatLngZoom(target, 18));
    AppLogger.debug('Map focus: camera moved');
    _select(capsule);
  }

  Future<void> _zoomBy(CameraUpdate update) async {
    unawaited(HapticFeedback.selectionClick());
    final controller = await _mapController.future;
    _expectCameraMove();
    await controller.animateCamera(update);
  }

  /// The compass: the map turns back to north (and flat), staying where it is.
  Future<void> _faceNorth() async {
    final camera = _viewport.value?.camera;
    if (camera == null) return;
    unawaited(HapticFeedback.selectionClick());
    final controller = await _mapController.future;
    _expectCameraMove();
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: camera.target, zoom: camera.zoom),
      ),
    );
  }

  /// A tap on a numbered bubble: the camera moves in on its capsules.
  Future<void> _zoomTo(MapItem cluster) async {
    final controller = await _mapController.future;
    final b = cluster.bounds!;
    if ((b.north - b.south).abs() < 1e-4 && (b.east - b.west).abs() < 1e-4) {
      // All in one spot: closer, around it.
      final zoom = await controller.getZoomLevel();
      _expectCameraMove();
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(cluster.at.latitude, cluster.at.longitude),
          zoom + 2,
        ),
      );
      return;
    }
    _expectCameraMove();
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
    _expectCameraMove();
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

  // Marker sets are rebuilt only when the capsules, the icons or
  // the zoom band change (F-10): a new Marker carries a new tap closure, so
  // rebuilding them on every position update or frame made the plugin send
  // every marker to the native map again.
  Object? _capsuleMarkersKey;
  Set<Marker> _capsuleMarkers = const {};
  GeoPosition? _userMarkerAt;
  Marker? _userMarker;

  /// Where the floating pins stand (those not inside a cluster or off
  /// screen).
  Map<String, LatLng> _floatingSpots = const {};

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
              // Above every capsule and bubble.
              zIndexInt: 4,
              position: LatLng(me.latitude, me.longitude),
            );
    }
    // Only what is on screen, clustered (MapController.items): every marker
    // update runs on Android's main thread.
    final key = (map.itemsVersion, icons.capsulePins);
    if (_choreographyDue && key == _capsuleMarkersKey) {
      _choreographyDue = false;
      _choreograph(map);
    }
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
              onTap: () {
                // The map centres a tapped pin.
                _expectCameraMove();
                _select(capsule);
              },
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
      _choreograph(map);
    }
    final user = _userMarker;
    // A floating pin's own marker hides while Flutter draws it, and shows it
    // posed while the map moves (one update each way).
    _floatingSpots = SelectedPin.spots(_capsuleMarkers, _floating.keys);
    // A deselected pin no longer on the map (in a cluster, the heatmap) has
    // nothing to land on.
    _floating.removeWhere(
      (id, pin) => pin.phase != _Float.up && !_floatingSpots.containsKey(id),
    );
    final hidden = <String>[];
    final posed = <String, (SelectedPinPose, BitmapDescriptor)>{};
    final shadowed = <String>[];
    for (final MapEntry(key: id, value: pin) in _floating.entries) {
      // The shadow from the selection until the pin starts landing: it
      // never changes, so it never blinks.
      if (pin.phase == _Float.up) shadowed.add(id);
      if (pin.phase == _Float.landed) continue;
      if (!pin.native) {
        hidden.add(id);
        continue;
      }
      // Not yet off the ground it looks like the plain pin, which stays.
      final bitmap = icons.selectedPin(pin.capsule.color);
      if (pin.motion.ms > 0 && bitmap != null) {
        hidden.add(id);
        posed[id] = (pin.motion.pose, bitmap);
      }
    }
    final pins = SelectedPin.apply(
      // What has landed (M-03, M-04); the rest is still on its way.
      {..._choreography.markers},
      hidden: hidden,
      posed: posed,
      shadowed: shadowed,
      shadow: icons.selectedShadow,
    );
    return user == null ? pins : {user, ...pins};
  }

  /// The capsules the map should show now go to the choreography, which
  /// lets newcomers come in and leavers go (M-03, M-04).
  double? _choreographedZoom;

  /// The part of the map on screen for [camera] (its corners, turned).
  GeoBounds? _onScreen(CameraPosition camera) {
    final padding = _viewport.value?.padding;
    if (padding == null || !mounted) return null;
    final size = MediaQuery.sizeOf(context);
    final corners = [
      for (final c in [
        Offset.zero,
        Offset(size.width, 0),
        Offset(0, size.height),
        Offset(size.width, size.height),
      ])
        MapProjection.toLatLng(c, camera, size, padding),
    ];
    return GeoBounds(
      south: corners.map((c) => c.latitude).reduce(math.min),
      north: corners.map((c) => c.latitude).reduce(math.max),
      west: corners.map((c) => c.longitude).reduce(math.min),
      east: corners.map((c) => c.longitude).reduce(math.max),
    );
  }

  void _choreograph(MapController map) {
    // Under a finger the markers change at once, on the map itself (sprites
    // would trail a moving map), the old ones staying until the new ones are
    // drawn; a programmatic camera move (a button) waits to land them with
    // the show.
    final live = _pointers > 0;
    if (!_still && !live) {
      _choreographyDue = true;
      return;
    }
    final animate = !AppMotion.reduced(context) && !live;
    if (!_firstShown && animate && _capsuleMarkers.isNotEmpty) {
      // From the first stop, or from now when the map has not stopped yet.
      final from = _firstStop ?? (_firstAsked ??= DateTime.now());
      final wait = from.add(_mapDraws).difference(DateTime.now());
      if (wait > Duration.zero) {
        _firstShowTimer?.cancel();
        _firstShowTimer = Timer(wait, () {
          if (mounted) setState(() => _choreographyDue = true);
        });
        return;
      }
    }
    if (_capsuleMarkers.isNotEmpty) _firstShown = true;
    final ratio = map.pixelRatio;
    final items = {for (final item in map.items) item.id: item};
    final view = _viewport.value;
    final size = MediaQuery.sizeOf(context);
    // A pin a little past the edge still shows part of itself.
    final screenRect = (Offset.zero & size).inflate(48);
    Offset? screen(LatLng p) {
      if (view == null) return null;
      final o = MapProjection.toScreen(p, view.camera, size, view.padding);
      return screenRect.contains(o) ? o : null;
    }

    final shown = <ShownMarker>[];
    for (final marker in _capsuleMarkers) {
      final item =
          items[marker.markerId.value] ??
          items['capsule:${marker.markerId.value}'];
      MarkerLook? look;
      if (item?.capsule case final capsule?) {
        final image = MarkerIcons.pinPicture(capsule.color);
        if (image != null) {
          look = MarkerLook(image, const Size.square(48), const Offset(0.5, 1));
        }
      } else if (item != null) {
        if (ClusterIcons.picture(item.count, ratio) case (
          final image,
          final side,
        )) {
          look = MarkerLook(image, Size.square(side), const Offset(0.5, 0.5));
        }
      }
      shown.add(ShownMarker(marker, look: look, bounds: item?.bounds));
    }
    // Zooming in, the old bubbles open into the new markers; zooming
    // out, the old ones gather into them.
    final zoom = view?.camera.zoom;
    final last = _choreographedZoom;
    _choreographedZoom = zoom;
    _choreography.update(
      shown,
      zoomingIn: zoom == null || last == null ? null : zoom > last + 0.01,
      zoomingOut: zoom == null || last == null ? null : zoom < last - 0.01,
      screen: screen,
      centre: view == null
          ? size.center(Offset.zero)
          : MapProjection.toScreen(
              view.camera.target,
              view.camera,
              size,
              view.padding,
            ),
      still: {for (final id in _floating.keys) MarkerId(id)},
      animate: animate,
      linger: live,
    );
    _choreographyVersion++;
    if (_choreography.trickling) {
      _trickleSoon();
    } else if (_choreography.lingering) {
      _dropLingeringSoon();
    }
  }

  /// Under a finger the new markers go onto the map a few at a time
  /// ([MarkerChoreography.trickle]); the old ones go once the last are drawn.
  static const _trickleBatch = 12;
  static const _trickleStep = Duration(milliseconds: 16);
  Timer? _trickleTimer;

  void _trickleSoon() {
    if (_trickleTimer?.isActive ?? false) return;
    _trickleTimer = Timer(_trickleStep, () {
      if (!mounted) return;
      setState(() => _choreography.trickle(_trickleBatch));
      if (_choreography.trickling) {
        _trickleSoon();
      } else {
        _dropLingeringSoon();
      }
    });
  }

  void _dropLingeringSoon() => unawaited(
    _afterNativeMap(() {
      if (_choreography.trickling) return;
      _choreography.dropLingering();
      setState(() {});
    }, settle: const Duration(milliseconds: 120)),
  );

  /// The coming capsules have landed: the map shows them now, and their
  /// sprites go once it has drawn them (an added marker shows once its
  /// bitmap has loaded).
  void _actLanded(int act) {
    if (!mounted) return;
    setState(() {});
    unawaited(
      _afterNativeMap(() {
        _choreography.handedOver(act);
        setState(() {});
      }, settle: const Duration(milliseconds: 250)),
    );
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
    final mapPadding = EdgeInsets.only(
      top: MediaQuery.viewPaddingOf(context).top,
      bottom: NavbarWidget.coveredHeight(context) + 4 + raised,
    );
    final camera = CameraPosition(
      target: LatLng(start.latitude, start.longitude),
      zoom: map.initialCameraZoom,
    );
    if (_askedPadding != mapPadding) {
      if (_askedPadding == null) {
        _viewport.start(camera, mapPadding);
      } else {
        _viewport.asked(mapPadding);
        unawaited(_confirmPadding());
      }
      _askedPadding = mapPadding;
    }
    final markers = _markers(map);
    if (_heatmapVersion != map.capsulesVersion) {
      _heatmapVersion = map.capsulesVersion;
      if (_heatmap.setCapsules(map.heatCapsules)) {
        // Only new places redraw the heat; panning never does.
        MapStats.instance.heatCleared();
        unawaited(
          _mapController.future.then(
            (c) => c.clearTileCache(CapsuleHeatmap.id),
          ),
        );
      }
    }
    final style = dark ? MapStyles.dark : MapStyles.light;
    final tiles = {
      TileOverlay(
        tileOverlayId: CapsuleHeatmap.id,
        tileProvider: _heatmap,
        visible: !map.showMarkers,
        // Every level looks the same: a fade would only show two
        // see-through layers over each other for a moment.
        fadeIn: false,
      ),
    };
    MapStats.instance.built(markers: markers, tiles: tiles, style: style);
    final spots = _floatingSpots;
    return PopScope(
      // Back closes the card first.
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(null);
      },
      child: Stack(
        children: [
          // A finger on the map: the map draws the floating pins until it
          // is still again (they would trail it).
          Listener(
            onPointerDown: _pointerDown,
            onPointerUp: _pointerUp,
            onPointerCancel: _pointerUp,
            child: GoogleMap(
              style: style,
              // The Google logo stays visible above the floating navigation
              // bar, above the capsule card while it is open, and below the
              // status bar: it is never covered (F-12, F-14). The zoom buttons
              // were hidden under the bar (pinch zooms).
              padding: mapPadding,
              zoomControlsEnabled: false,
              // Flat only: the selected pin's overlay places itself on a flat
              // map (MapProjection).
              tiltGesturesEnabled: false,
              // Our compass sits with the zoom and location buttons.
              compassEnabled: false,
              // The capsule card replaces Google's marker toolbar.
              mapToolbarEnabled: false,
              mapType: switch (look) {
                MapLook.standard => MapType.normal,
                MapLook.satellite => MapType.satellite,
                MapLook.hybrid => MapType.hybrid,
              },
              initialCameraPosition: _viewport.value?.camera ?? camera,
              onMapCreated: (controller) {
                if (!_mapController.isCompleted) {
                  _mapController.complete(controller);
                }
                if (MapStats.enabled) {
                  MapStats.instance.moveCamera = (target, zoom) => controller
                      .moveCamera(CameraUpdate.newLatLngZoom(target, zoom));
                }
                if (_focus.pending != null) unawaited(_showFocusedCapsule());
              },
              markers: markers,
              // Far out, where capsules are, as heat (M-11).
              tileOverlays: tiles,
              onTap: (_) => _select(null),
              onCameraMoveStarted: _cameraStarted,
              onCameraMove: (position) {
                MapStats.instance.cameraMoved();
                _viewport.moved(position);
                _bearing.value = position.bearing;
                // Zoomed out to the heatmap: no pins, their card goes too.
                if (position.zoom < MapController.markerZoomThreshold) {
                  _select(null);
                }
                // Under a finger the markers follow the zoom at once, so
                // they need to know what is on screen now.
                map.onCameraMove(
                  position.zoom,
                  view: _pointers > 0 ? _onScreen(position) : null,
                );
              },
              onCameraIdle: () async {
                MapStats.instance.cameraIdle();
                _cameraStopped();
                final controller = await _mapController.future;
                try {
                  final bounds = await controller.getVisibleRegion();
                  final center = GeoPosition(
                    (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
                    (bounds.northeast.longitude + bounds.southwest.longitude) /
                        2,
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
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: MarkerChoreographyOverlay(
                choreography: _choreography,
                view: _viewport,
                version: _choreographyVersion,
                onLanded: _actLanded,
              ),
            ),
          ),
          // Kept while the map draws the pin, only not painted: built again
          // when a finger lifts, its picture came a frame late.
          for (final MapEntry(key: id, value: pin) in _floating.entries)
            if (spots[id] case final spot?)
              Positioned.fill(
                key: ValueKey(id),
                child: IgnorePointer(
                  child: Opacity(
                    opacity: pin.drawn ? 1 : 0,
                    child: SelectedPinOverlay(
                      color: pin.capsule.color,
                      spot: spot,
                      view: _viewport,
                      motion: pin.motion,
                      running: pin.running,
                      onLanded: () => _landed(id),
                    ),
                  ),
                ),
              ),
          if (MapStats.harness)
            const Positioned(top: 0, left: 0, child: MapHarnessStrip()),
          // What the map shows (B5), top left under the status bar.
          Positioned(
            top: MediaQuery.viewPaddingOf(context).top + 12,
            left: 16,
            child: _FilterButton(
              active: map.filter.activeCount,
              onTap: () => MapFilterSheet.show(
                context,
                filter: map.filter,
                onChanged: map.setFilter,
              ),
            ),
          ),
          // The streak (B7), top right: grey with an orange ring while
          // today is not counted yet.
          Positioned(
            top: MediaQuery.viewPaddingOf(context).top + 12,
            right: 16,
            child: const StreakPill(),
          ),
          AnimatedPositioned(
            duration: motion,
            curve: AppMotion.emphasizedCurve,
            right: 16,
            // Moves up while a capsule card (or the hint) is shown.
            bottom: bottom + raised,
            child: _MyLocationButton(onTap: () => _goToMe(map)),
          ),
          // Zoom, above the my-location button (pinch still works).
          AnimatedPositioned(
            duration: motion,
            curve: AppMotion.emphasizedCurve,
            right: 16,
            bottom:
                bottom + raised + AppSizes.mapControl + AppSizes.mapControlGap,
            child: _ZoomButtons(
              onZoomIn: () => unawaited(_zoomBy(CameraUpdate.zoomIn())),
              onZoomOut: () => unawaited(_zoomBy(CameraUpdate.zoomOut())),
            ),
          ),
          // Compass, above the zoom pill while the map is turned.
          AnimatedPositioned(
            duration: motion,
            curve: AppMotion.emphasizedCurve,
            right: 16,
            bottom:
                bottom +
                raised +
                AppSizes.mapControl * 3 +
                1 +
                AppSizes.mapControlGap * 2,
            child: MapCompass(
              size: AppSizes.mapControl,
              bearing: _bearing,
              onTap: () => unawaited(_faceNorth()),
            ),
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

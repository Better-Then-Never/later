import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/session/session_controller.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/capsule.dart';
import '../../data/models/geo_position.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/location_service.dart';
import 'current_location.dart';
import 'marker_icons.dart';

enum MapLoadState { loading, ready }

/// State of the map screen: where to start the camera, the user's position
/// and the capsules the user may see.
///
/// Fixes BUG-041 (endless loader without a location fix: a fresh fix is
/// awaited for a few seconds, then the last known position, then a world
/// view), BUG-043 (the whole `capsules` collection, private ones included,
/// was streamed and re-subscribed on every rebuild: now three bounded,
/// visibility-correct queries owned by this controller) and BUG-046.
class MapController extends ChangeNotifier {
  MapController({
    required CapsuleRepository capsules,
    required LocationService location,
    required CurrentLocation currentLocation,
    required SessionController session,
  }) : _capsules = capsules,
       _location = location,
       _currentLocation = currentLocation,
       _session = session;

  final CapsuleRepository _capsules;
  final LocationService _location;
  final CurrentLocation _currentLocation;
  final SessionController _session;

  /// Camera used when no position is known at all.
  static const fallbackCamera = GeoPosition(20, 0);
  static const fallbackZoom = 2.0;
  static const initialZoom = 13.0;

  /// Markers are drawn from this zoom level; below it only the heatmap.
  static const markerZoomThreshold = 12.0;

  /// Public capsules are loaded for a latitude band of ±[_bandHalfHeight]
  /// degrees around the camera and reloaded when the camera leaves its inner
  /// half.
  static const _bandHalfHeight = 2.0;

  MapLoadState _state = MapLoadState.loading;
  MarkerIcons? _icons;
  GeoPosition? _initialCamera;
  bool _usedFallbackCamera = false;
  LocationAvailability _availability = LocationAvailability.available;
  double _zoom = initialZoom;
  double? _bandCenter;

  List<Capsule> _own = const [];
  List<Capsule> _friends = const [];
  List<Capsule> _public = const [];
  List<String> _friendIds = const [];

  StreamSubscription<GeoPosition>? _positionSub;
  StreamSubscription<List<Capsule>>? _ownSub;
  StreamSubscription<List<Capsule>>? _friendsSub;
  StreamSubscription<List<Capsule>>? _publicSub;
  bool _disposed = false;

  MapLoadState get state => _state;
  MarkerIcons? get icons => _icons;
  GeoPosition get initialCamera => _initialCamera ?? fallbackCamera;
  double get initialCameraZoom =>
      _usedFallbackCamera ? fallbackZoom : initialZoom;
  bool get usedFallbackCamera => _usedFallbackCamera;
  LocationAvailability get availability => _availability;
  GeoPosition? get myPosition => _currentLocation.position;
  double get zoom => _zoom;
  bool get showMarkers => _zoom >= markerZoomThreshold;

  /// Changes whenever the capsules on the map change (not on position
  /// updates or zoom): the map page rebuilds its markers only then (F-10).
  int get capsulesVersion => _capsulesVersion;
  int _capsulesVersion = 0;
  List<Capsule>? _visible;

  /// Every capsule the signed-in user may see, de-duplicated; computed once
  /// per change of the capsule lists.
  List<Capsule> get visibleCapsules => _visible ??= _computeVisible();

  List<Capsule> _computeVisible() {
    final uid = _session.uid;
    final friends = _friendIds.toSet();
    final byId = <String, Capsule>{};
    for (final c in [..._public, ..._friends, ..._own]) {
      if (c.location == null) continue; // malformed: cannot be placed
      if (isVisibleTo(c, uid: uid, friendIds: friends)) byId[c.id] = c;
    }
    return List.unmodifiable(byId.values);
  }

  void _capsulesChanged() {
    _visible = null;
    _capsulesVersion++;
  }

  /// The capsule visibility rule (also enforced by the Firestore rules).
  static bool isVisibleTo(
    Capsule c, {
    required String? uid,
    required Set<String> friendIds,
  }) =>
      c.ownerId == uid ||
      c.privacy == CapsulePrivacy.public ||
      (c.privacy == CapsulePrivacy.friends && friendIds.contains(c.ownerId));

  Future<void> start() async {
    final uid = _session.uid;
    if (uid == null) return;

    _icons = await MarkerIcons.load(dark: _darkIcons);
    _availability = await _location.availability();
    // Fastest first: a position already known in this session, then the
    // OS last-known fix (instant), and only then wait for a fresh fix.
    final position =
        _currentLocation.position ??
        await _location.lastKnownPosition() ??
        await _location.currentPosition(timeout: const Duration(seconds: 5));
    if (_disposed) return;

    _currentLocation.update(position);
    _initialCamera = position;
    _usedFallbackCamera = position == null;
    _state = MapLoadState.ready;
    notifyListeners();

    if (_availability == LocationAvailability.available) _followPosition();

    _ownSub = _capsules
        .watchOwn(uid)
        .listen(
          (list) => _set(() => _own = list),
          onError: _logStreamError('own'),
        );
    _session.addListener(_onSessionChanged);
    _onSessionChanged();
    _loadPublicBand(initialCamera.latitude);
  }

  bool _darkIcons = false;

  /// Theme of the markers (see [MarkerIcons.load]); call before [start] and
  /// whenever the theme changes.
  Future<void> setDarkIcons(bool dark) async {
    if (dark == _darkIcons) return;
    _darkIcons = dark;
    if (_icons == null) return; // start() loads them
    final icons = await MarkerIcons.load(dark: dark);
    if (_disposed || dark != _darkIcons) return;
    _icons = icons;
    notifyListeners();
  }

  void _followPosition() {
    _positionSub ??= _location.positions().listen((p) {
      _currentLocation.update(p);
      notifyListeners();
    }, onError: (Object e) => AppLogger.debug('Position stream: $e'));
  }

  /// The my-location button (F-13): asks for the permission when it was
  /// not given yet, then returns where the user is; null when that is not
  /// possible ([availability] says why).
  Future<GeoPosition?> locateMe() async {
    _availability = await _location.availability(request: true);
    if (_disposed) return null;
    if (_availability != LocationAvailability.available) {
      notifyListeners();
      return null;
    }
    _followPosition();
    final position =
        _currentLocation.position ??
        await _location.currentPosition(timeout: const Duration(seconds: 5));
    if (_disposed) return null;
    _currentLocation.update(position);
    notifyListeners();
    return position;
  }

  void _onSessionChanged() {
    final friends = _session.profile?.friends ?? const <String>[];
    if (listEquals(friends, _friendIds)) return;
    _friendIds = List.of(friends);
    _capsulesChanged();
    unawaited(_friendsSub?.cancel());
    _friendsSub = _capsules
        .watchFriends(_friendIds)
        .listen(
          (list) => _set(() => _friends = list),
          onError: _logStreamError('friends'),
        );
    notifyListeners();
  }

  void _loadPublicBand(double centerLatitude) {
    _bandCenter = centerLatitude;
    unawaited(_publicSub?.cancel());
    _publicSub = _capsules
        .watchPublicInBand(
          centerLatitude - _bandHalfHeight,
          centerLatitude + _bandHalfHeight,
        )
        .listen(
          (list) => _set(() => _public = list),
          onError: _logStreamError('public'),
        );
  }

  /// Called when the camera stops moving.
  void onCameraIdle(GeoPosition center, double zoom) {
    final band = _bandCenter;
    if (band == null || (center.latitude - band).abs() > _bandHalfHeight / 2) {
      _loadPublicBand(center.latitude);
    }
    _setZoom(zoom);
  }

  /// Called while the camera moves; only crossing the marker threshold
  /// triggers a rebuild.
  void onCameraMove(double zoom) => _setZoom(zoom);

  void _setZoom(double zoom) {
    final crossed =
        (zoom >= markerZoomThreshold) != (_zoom >= markerZoomThreshold);
    _zoom = zoom;
    if (crossed) notifyListeners();
  }

  void _set(VoidCallback update) {
    _capsulesChanged();
    if (_disposed) return;
    update();
    AppLogger.debug(
      'Map capsules: own=${_own.length} friends=${_friends.length} '
      'public=${_public.length} visible=${visibleCapsules.length}',
    );
    notifyListeners();
  }

  void Function(Object, StackTrace) _logStreamError(String name) =>
      (e, st) => AppLogger.warning(
        'Map capsules stream ($name) failed',
        error: e,
        stackTrace: st,
      );

  @override
  void dispose() {
    _disposed = true;
    _session.removeListener(_onSessionChanged);
    unawaited(_positionSub?.cancel());
    unawaited(_ownSub?.cancel());
    unawaited(_friendsSub?.cancel());
    unawaited(_publicSub?.cancel());
    super.dispose();
  }
}

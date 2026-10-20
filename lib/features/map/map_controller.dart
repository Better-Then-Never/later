import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'
    show BitmapDescriptor;

import '../../app/session/session_controller.dart';
import '../../app/shell/startup_report.dart';
import '../../core/logging/app_logger.dart';
import '../../data/models/capsule.dart';
import '../../data/models/geo_position.dart';
import '../../data/repositories/repositories.dart';
import '../../data/services/location_service.dart';
import 'cluster_icons.dart';
import 'engine/map_camera_memory.dart';
import 'current_location.dart';
import 'map_clusters.dart';
import 'map_stats.dart';
import 'marker_icons.dart';
import '../../data/services/preferences_store.dart';
import 'map_filter.dart';
import 'map_delta_sync.dart';
import 'map_pin_store.dart';
import '../../core/config/feature_flags.dart';

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
    PreferencesStore? prefs,
    MapPinStore? pinStore,
    this.groupsMarkers = true,
    this.deltaSync = FeatureFlags.mapDeltaSync,
  }) : _prefs = prefs,
       _pinStore = pinStore,
       _capsules = capsules,
       _location = location,
       _currentLocation = currentLocation,
       _session = session;

  final CapsuleRepository _capsules;
  final MapPinStore? _pinStore;
  final LocationService _location;
  final CurrentLocation _currentLocation;
  final SessionController _session;
  final PreferencesStore? _prefs;

  /// Whether this controller groups the capsules into markers for the
  /// screen (the Google map). MapLibre groups them itself: then nothing is
  /// grouped here, and a stopped camera costs Flutter nothing.
  final bool groupsMarkers;

  /// The friends' and public capsules from the pin store and what changed
  /// since ([MapDeltaSync]); else read in full at every start.
  final bool deltaSync;

  static const _filterKey = 'map_filter';

  /// What the map shows (B5); everything by default.
  MapFilter _filter = MapFilter.all;
  MapFilter get filter => _filter;

  void setFilter(MapFilter value) {
    if (value == _filter) return;
    _set(() => _filter = value);
    final uid = _session.uid;
    final prefs = _prefs;
    if (uid != null && prefs != null) {
      unawaited(prefs.setString(uid, _filterKey, value.encode()));
    }
  }

  Future<void> _loadFilter(String uid) async {
    final saved = await _prefs?.string(uid, _filterKey);
    if (_disposed || saved == null) return;
    final filter = MapFilter.decode(saved);
    if (filter != _filter) _set(() => _filter = filter);
  }

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
  List<Capsule> _coAuthored = const [];
  List<Capsule> _friends = const [];
  List<Capsule> _public = const [];

  /// Every public capsule loaded this session, from every band: the heatmap
  /// keeps their places, so panning into a new band never takes heat away
  /// or redraws it (M-11). Kept until the app restarts.
  final Map<String, Capsule> _publicSeen = {};
  List<String> _friendIds = const [];

  StreamSubscription<GeoPosition>? _positionSub;
  StreamSubscription<List<Capsule>>? _ownSub;
  StreamSubscription<List<Capsule>>? _coSub;
  StreamSubscription<List<Capsule>>? _friendsSub;
  StreamSubscription<List<Capsule>>? _publicSub;
  bool _disposed = false;

  MapLoadState get state => _state;
  MarkerIcons? get icons => _icons;
  GeoPosition get initialCamera => _initialCamera ?? fallbackCamera;
  double get initialCameraZoom =>
      _savedZoom ?? (_usedFallbackCamera ? fallbackZoom : initialZoom);

  /// The zoom of the camera saved when the map last stopped (null: none).
  double? _savedZoom;

  /// The longest a start waits for the phone's last known position before
  /// it opens where the map last stopped instead.
  static const _whereAtMost = Duration(milliseconds: 300);
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
  List<Capsule> get visibleCapsules => _visible ??= _computeVisible(_public);

  /// What the heatmap shows: as [visibleCapsules], with the public capsules
  /// of every band seen so far (M-11).
  List<Capsule> get heatCapsules =>
      _heat ??= _computeVisible(_publicSeen.values);
  List<Capsule>? _heat;

  /// What the map shows at marker zoom: pins and numbered bubbles for the
  /// part on screen (see [clusterCapsules]), recomputed when the camera stops
  /// or the capsules change, never while it moves. Empty until the first
  /// camera stop and below [markerZoomThreshold] (the heatmap shows then).
  List<MapItem> get items => _items;
  List<MapItem> _items = const [];

  /// Changes whenever [items] change: the map page rebuilds markers only then.
  int get itemsVersion => _itemsVersion;
  int _itemsVersion = 0;

  GeoBounds? _view;
  int _clusterRun = 0;
  final Map<String, BitmapDescriptor> _clusterIcons = {};

  /// Device pixel ratio for the bubble bitmaps (set by the map page).
  double pixelRatio = 3;

  /// The bubble for a cluster of [count] (ready whenever [items] has it).
  BitmapDescriptor? clusterIcon(int count) =>
      _clusterIcons[ClusterIcons.label(count)];

  Future<void> _recluster() async {
    if (!groupsMarkers) return;
    final view = _view;
    final run = ++_clusterRun;
    _clusteredLevel = showMarkers ? _zoom.floor() : -1;
    if (view == null || !showMarkers) {
      if (_items.isEmpty) return;
      _items = const [];
      _itemsVersion++;
      notifyListeners();
      return;
    }
    final watch = Stopwatch()..start();
    final items = clusterCapsules(visibleCapsules, view: view, zoom: _zoom);
    MapStats.instance.clustered(watch.elapsedMicroseconds);
    for (final item in items) {
      if (!item.isCluster) continue;
      final label = ClusterIcons.label(item.count);
      if (_clusterIcons.containsKey(label)) continue;
      _clusterIcons[label] = await ClusterIcons.forCount(
        item.count,
        pixelRatio,
      );
    }
    if (_disposed || run != _clusterRun) return;
    _items = items;
    _itemsVersion++;
    notifyListeners();
  }

  List<Capsule> _computeVisible(Iterable<Capsule> public) {
    final uid = _session.uid;
    final friends = _friendIds.toSet();
    final now = DateTime.now();
    final byId = <String, Capsule>{};
    // Each source as it answered, or as the map last showed it until then
    // (the pin store); its stored pins go with its first answer. The
    // visibility rule runs on the stored ones too, with today's friends: a
    // friend removed since takes their friends-only pins at once.
    List<Capsule> of(String source, Iterable<Capsule> live) =>
        _answered.contains(source)
        ? List.of(live)
        : _stored[source] ?? const [];
    for (final c in [
      ...of('public', public),
      ...of('friends', _friends),
      ...of('own', _own),
      ...of('co', _coAuthored),
    ]) {
      if (c.location == null) continue; // malformed: cannot be placed
      if (!isVisibleTo(c, uid: uid, friendIds: friends)) continue;
      if (!_filter.accepts(c, uid: uid, friendIds: friends, now: now)) {
        continue;
      }
      byId[c.id] = c;
    }
    return List.unmodifiable(byId.values);
  }

  void _capsulesChanged() {
    _visible = null;
    _heat = null;
    _capsulesVersion++;
  }

  /// The capsule visibility rule (also enforced by the Firestore rules).
  static bool isVisibleTo(
    Capsule c, {
    required String? uid,
    required Set<String> friendIds,
  }) =>
      c.ownerId == uid ||
      (uid != null && c.coAuthors.contains(uid)) ||
      c.privacy == CapsulePrivacy.public ||
      (c.privacy == CapsulePrivacy.friends && friendIds.contains(c.ownerId));

  /// The capsules are asked for first: they are the slow part, and they
  /// never wait for the location. The map opens on the user (the owner's
  /// choice, 20 Oct 2026): at the phone's last known position, asked for
  /// at most [_whereAtMost] (about 0.1 s), at the zoom the map was last
  /// left at; without a position where the map last stopped
  /// ([MapCameraMemory]); on a first start, with nothing saved, a fresh fix
  /// is waited for (at most 5 s), then a world view.
  Future<void> start() async {
    final uid = _session.uid;
    if (uid == null) return;
    StartupReport.mark('map_start');
    _watchCapsules(uid);
    unawaited(_readStore(uid));
    unawaited(_loadFilter(uid));

    final prefs = _prefs;
    final saved = MapCameraMemory.parse(
      prefs?.stringSync(uid, MapCameraMemory.key) ??
          await prefs?.string(uid, MapCameraMemory.key),
    );
    if (_disposed) return;
    _savedZoom = saved?.$3;

    // Google's marker bitmaps (MapLibre draws its own).
    if (groupsMarkers) _icons = await MarkerIcons.load(dark: _darkIcons);
    // Where the user is: a position already known in this session, else
    // the phone's last known fix (both asked at once, never waited for
    // long); a fresh fix only on a first start, with nowhere saved.
    final (availability, lastKnown) =
        await (
          _location.availability(),
          _currentLocation.position != null
              ? Future.value(_currentLocation.position)
              : _location.lastKnownPosition(),
        ).wait.timeout(
          _whereAtMost,
          onTimeout: () => (LocationAvailability.available, null),
        );
    _availability = availability;
    final position =
        lastKnown ??
        (saved == null
            ? await _location.currentPosition(
                timeout: const Duration(seconds: 5),
              )
            : null);
    if (_disposed) return;
    StartupReport.mark('map_position');

    _currentLocation.update(position);
    _initialCamera =
        position ?? (saved == null ? null : GeoPosition(saved.$1, saved.$2));
    _usedFallbackCamera = _initialCamera == null;
    _state = MapLoadState.ready;
    _wantBand(initialCamera.latitude);
    notifyListeners();

    if (_availability == LocationAvailability.available) _followPosition();
  }

  void _watchCapsules(String uid) {
    _ownSub = _capsules
        .watchOwn(uid)
        .listen(
          (list) => _set(() => _own = list, answered: 'own'),
          onError: _logStreamError('own'),
        );
    _coSub = _capsules
        .watchCoAuthored(uid)
        .listen(
          (list) => _set(() => _coAuthored = list, answered: 'co'),
          onError: _logStreamError('co-authored'),
        );
  }

  /// The friends' and public capsules, once the store has been read: from
  /// what it kept and what changed since ([MapDeltaSync]), or all of them.
  void _startShared(StoredMap stored) {
    _sharedStarted = true;
    _session.addListener(_onSessionChanged);
    if (deltaSync && stored.syncedTo != null && stored.bandLatitude != null) {
      _friendIds = List.of(_session.profile?.friends ?? const <String>[]);
      _bandCenter = stored.bandLatitude;
      StartupReport.mark('sync_delta');
      _delta = MapDeltaSync(
        capsules: _capsules,
        stored: stored,
        friendIds: _friendIds,
        onChanged: _deltaChanged,
        onFailed: (_) => _readEverything(),
      )..start();
      return;
    }
    _onSessionChanged();
    if (_bandWanted case final band?) _loadPublicBand(band);
  }

  /// The map's sync of friends' and public capsules (null: they are read
  /// in full).
  MapDeltaSync? _delta;
  bool _sharedStarted = false;

  /// The public band's latitude wanted before the store was read.
  double? _bandWanted;

  void _wantBand(double latitude) {
    _bandWanted = latitude;
    if (_sharedStarted && _delta == null && _publicSub == null) {
      _loadPublicBand(latitude);
    }
  }

  void _deltaChanged() {
    final delta = _delta;
    if (delta == null) return;
    _set(
      () {
        _friends = delta.friends;
        _public = delta.public;
        for (final c in _public) {
          _publicSeen[c.id] = c;
        }
      },
      answered: [
        if (delta.friendsAnswered) 'friends',
        if (delta.publicAnswered) 'public',
      ],
    );
  }

  /// The sync cannot be trusted (an error, a limit, the friends changed, a
  /// far-away band): the friends' and public capsules are read in full; the
  /// kept pins stand in until they answer.
  void _readEverything() {
    final delta = _delta;
    if (delta == null) return;
    _delta = null;
    delta.dispose();
    _answered
      ..remove('friends')
      ..remove('public');
    _friendsSub = null;
    _onSessionChanged();
    _loadPublicBand(_bandCenter ?? _bandWanted ?? initialCamera.latitude);
    _capsulesChanged();
    notifyListeners();
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
    if (_delta != null) {
      if (!listEquals(friends, _friendIds)) _readEverything();
      return;
    }
    // The first time even with no friends: their source answers (empty),
    // or the map never knows it has everything.
    if (_friendsSub != null && listEquals(friends, _friendIds)) return;
    _friendIds = List.of(friends);
    _capsulesChanged();
    unawaited(_friendsSub?.cancel());
    _friendsSub = _capsules
        .watchFriends(_friendIds)
        .listen(
          (list) => _set(() => _friends = list, answered: 'friends'),
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
          (list) => _set(() {
            _public = list;
            for (final c in list) {
              _publicSeen[c.id] = c;
            }
          }, answered: 'public'),
          onError: _logStreamError('public'),
        );
  }

  /// Called when the camera stops moving, with the part of the map on
  /// screen.
  void onCameraIdle(GeoPosition center, double zoom, {GeoBounds? view}) {
    final band = _bandCenter;
    if (band == null || (center.latitude - band).abs() > _bandHalfHeight / 2) {
      if (_delta != null) {
        _bandCenter = center.latitude;
        _readEverything();
      } else if (_sharedStarted) {
        _loadPublicBand(center.latitude);
      } else {
        _bandWanted = center.latitude;
      }
    }
    _setZoom(zoom);
    if (view != null) _view = view;
    unawaited(_recluster());
  }

  /// Called while the camera moves; only crossing the marker threshold
  /// triggers a rebuild. Under a finger ([view] given: what is on screen
  /// now) the markers follow at once whenever the zoom crosses a level:
  /// bubbles split and merge while the fingers are still down, not only
  /// once the map stops.
  void onCameraMove(double zoom, {GeoBounds? view}) {
    _setZoom(zoom);
    if (view == null) return;
    final level = showMarkers ? zoom.floor() : -1;
    if (level == _clusteredLevel) return;
    _view = view;
    unawaited(_recluster());
  }

  /// The zoom level the markers were last grouped for (-1: the heatmap).
  int? _clusteredLevel;

  void _setZoom(double zoom) {
    final crossed =
        (zoom >= markerZoomThreshold) != (_zoom >= markerZoomThreshold);
    _zoom = zoom;
    if (crossed) notifyListeners();
  }

  /// The sources that have answered at least once (own, co, friends,
  /// public).
  final _answered = <String>{};

  /// Every source has answered once: the capsules are all there.
  bool get allAnswered => _answered.length == 4;

  /// The pins the map showed last time on this phone, by source, until each
  /// source answers ([MapPinStore]).
  final _stored = <String, List<Capsule>>{};
  bool _storeRead = false;

  /// Every pin of this start is known: each source answered, or the pins
  /// the map last showed are there to stand in until they do.
  bool get complete => allAnswered || _storeRead;

  /// The stored pins' capsules (only what a pin needs).
  final _storedObjects = Set<Capsule>.identity();

  /// Shown from what the phone kept: only its pin is known (no source has
  /// sent it again, or the sync kept it). Opened through [freshCapsule],
  /// never from what was stored.
  bool isStoredOnly(String id) {
    for (final c in visibleCapsules) {
      if (c.id == id) return _storedObjects.contains(c);
    }
    return false;
  }

  /// [id] from the phone's copy of Firestore at once (null: not there): a
  /// stored pin's card opens with it while [freshCapsule] checks.
  Future<Capsule?> cachedCapsule(String id) async {
    try {
      return await _capsules.getCachedById(id);
    } on Object {
      return null;
    }
  }

  /// [id] as the server has it now, if this user may still see it (the
  /// rules decide): null when it was deleted, hidden or is no longer theirs
  /// to see.
  Future<Capsule?> freshCapsule(String id) async {
    try {
      final capsule = await _capsules.getById(id);
      final uid = _session.uid;
      if (capsule == null ||
          !isVisibleTo(capsule, uid: uid, friendIds: _friendIds.toSet())) {
        return null;
      }
      return capsule;
    } on Object catch (e) {
      AppLogger.warning('Capsule not read', error: e);
      return null;
    }
  }

  Future<void> _readStore(String uid) async {
    final stored = await _pinStore?.read(uid) ?? StoredMap.none;
    if (_disposed) return;
    if (stored.pins.isNotEmpty) {
      for (final pin in stored.pins) {
        (_stored[pin.source.name] ??= []).add(pin.capsule);
        _storedObjects.add(pin.capsule);
      }
      _storeRead = true;
      StartupReport.mark('store');
      _capsulesChanged();
      notifyListeners();
    }
    _startShared(stored);
  }

  /// The pins written to the store a moment after the last change, once
  /// every source has answered (only what the server returned).
  Timer? _saveTimer;

  void _scheduleSave() {
    if (_pinStore == null || !allAnswered) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _save);
  }

  void _save() {
    _saveTimer = null;
    final uid = _session.uid;
    final store = _pinStore;
    if (uid == null || store == null || !allAnswered) return;
    final friends = _friendIds.toSet();
    final byId = <String, StoredPin>{};
    void add(Iterable<Capsule> list, PinSource source) {
      for (final c in list) {
        if (c.location == null) continue;
        if (!isVisibleTo(c, uid: uid, friendIds: friends)) continue;
        byId[c.id] = StoredPin(c, source);
      }
    }

    // Later ones win: a capsule that is both its owner's and public belongs
    // to the owner's source.
    add(_public, PinSource.public);
    add(_friends, PinSource.friends);
    add(_coAuthored, PinSource.co);
    add(_own, PinSource.own);
    unawaited(
      store.save(
        uid,
        StoredMap(
          pins: byId.values.toList(),
          syncedTo: _delta?.syncedTo ?? _newest([..._friends, ..._public]),
          friendIds: List.of(_friendIds),
          bandLatitude: _bandCenter,
        ),
      ),
    );
  }

  /// The newest of [capsules]' server times: what a full answer holds up to.
  static DateTime? _newest(Iterable<Capsule> capsules) {
    DateTime? newest;
    for (final c in capsules) {
      final at = c.createdAt;
      if (at != null && (newest == null || at.isAfter(newest))) newest = at;
    }
    return newest;
  }

  void _set(VoidCallback update, {Object? answered}) {
    _capsulesChanged();
    if (_disposed) return;
    update();
    final sources = switch (answered) {
      final String one => [one],
      final List<String> some => some,
      _ => const <String>[],
    };
    for (final source in sources) {
      if (!_answered.add(source)) continue;
      StartupReport.mark('data_$source');
      if (allAnswered) StartupReport.mark('data_all');
    }
    _scheduleSave();
    unawaited(_recluster());
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
    _delta?.dispose();
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      _save();
    }
    _disposed = true;
    _session.removeListener(_onSessionChanged);
    unawaited(_positionSub?.cancel());
    unawaited(_ownSub?.cancel());
    unawaited(_coSub?.cancel());
    unawaited(_friendsSub?.cancel());
    unawaited(_publicSub?.cancel());
    super.dispose();
  }
}

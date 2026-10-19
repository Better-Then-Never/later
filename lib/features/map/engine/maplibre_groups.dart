part of '../map_page.dart';

/// A GeoJSON source's new data as a string, which MapLibre converts on a
/// worker thread. The plugin's setGeoJsonSource parses it into Java objects
/// on Android's main thread first (tens of milliseconds for a thousand
/// capsules), where the map's own animations run: it held up tap zooms and
/// the split and merge.
Future<void> _setSource(
  ml.MapLibreMapController c,
  String id,
  Map<String, dynamic> data,
) => c.editGeoJsonSource(id, jsonEncode(data));

/// The MapLibre map's pins and bubbles (mission 2, §2.1): grouped here
/// ([CapsuleGroups]) rather than by the map, so a bubble knows what it splits
/// into. One source ([_capsulesSource]) holds them all: those at rest and,
/// while the shown level changes, the moving ones in their pose of the
/// moment ([GroupMotion]), sent every frame. Every update is a whole picture,
/// so nothing is drawn twice or missing while pieces hand over (with a still
/// and a moving source, a landed piece was drawn twice for about 13 frames
/// and a vanished one could leave a gap: docs/map/FLASH_FIX.md). All in the
/// map's own space, so they move with it under the fingers.
class _GroupStage {
  _GroupStage({required TickerProvider vsync}) {
    _ticker = vsync.createTicker(_tick);
  }

  late final Ticker _ticker;
  final _clock = Stopwatch()..start();
  ml.MapLibreMapController? controller;
  CapsuleGroups groups = CapsuleGroups.empty;
  int? _level;
  GroupTransition _transition = GroupTransition.none;
  bool _sending = false;
  bool _dirty = false;
  int _run = 0;

  /// The pictures sent, counted (each feature carries its picture's number,
  /// so the flash probe can tell a late picture from a wrong one).
  int seq = 0;

  // The camera: its zoom, middle and reach (half the screen's diagonal and a
  // margin), in world units, and how fast the zoom changes (levels a second,
  // smoothed).
  double _zoom = 0;
  double _cx = 0;
  double _cy = 0;
  double _reach = 0;
  double _speed = 0;
  int _cameraAt = -1;

  /// The area the picture at rest holds (middle and radius, world units):
  /// three times the screen's reach, sent again once the screen leaves it.
  /// While pieces move, every frame holds 1.6 times the reach around the
  /// screen of that moment.
  (double, double, double)? _cover;

  /// The posed pins (the selected one, one landing): always pins of their
  /// own, even where the level holds them in a bubble (they grow and float:
  /// [_MapLibreMapViewState._sendPose]).
  List<GroupNode> _posed = const [];

  /// What the source holds now, and the last pictures sent by their number
  /// (for the flash probe only).
  final sent = <String, _Sent>{};
  final sentBySeq = <int, Map<String, _Sent>>{};

  /// The level whose pins and bubbles are shown (null before the first
  /// capsules).
  int? get level => _level;

  /// A split or merge is under way.
  bool get animating => _ticker.isActive;

  int get _now => _clock.elapsedMilliseconds;

  void dispose() => _ticker.dispose();

  /// A shown pin or bubble by its feature id.
  GroupNode? node(String id) {
    final level = _level;
    if (level == null) return null;
    for (final n in groups.at(level)) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// The capsules whose pins are posed (selected, landing).
  set posed(Iterable<Capsule> capsules) {
    final next = [
      for (final c in capsules)
        if (c.location case final at?)
          GroupNode.pin(
            GroupPoint(c.id, at.latitude, at.longitude, c.color.name),
          ),
    ];
    // Only those their level does not show as pins change the picture.
    final level = _level;
    final shownPins = level == null
        ? const <String>{}
        : {
            for (final n in groups.at(level))
              if (!n.isBubble) n.id,
          };
    final before = {
      for (final n in _posed)
        if (!shownPins.contains(n.id)) n.id,
    };
    _posed = next;
    final after = {
      for (final n in next)
        if (!shownPins.contains(n.id)) n.id,
    };
    if (before.length != after.length || !before.containsAll(after)) _send();
  }

  /// New capsules (or a filter): grouped off Flutter's UI thread; the
  /// picture follows, nothing flies.
  Future<void> setCapsules(Iterable<Capsule> capsules) async {
    final run = ++_run;
    final points = [
      for (final c in capsules)
        if (c.location case final at?)
          GroupPoint(c.id, at.latitude, at.longitude, c.color.name),
    ];
    final watch = Stopwatch()..start();
    final built = await compute(CapsuleGroups.build, points);
    MapStats.instance.clustered(watch.elapsedMicroseconds);
    if (run != _run) return;
    groups = built;
    _level ??= CapsuleGroups.levelFor(_zoom);
    restart();
  }

  /// Everything as it should stand now, no flight (a new style, new data).
  void restart() {
    _ticker.stop();
    _transition = GroupTransition.none;
    _send();
  }

  /// The camera moved ([reachDp]: half the screen's diagonal). When the
  /// shown level changes, the bubbles split or merge, those on screen moving
  /// from the middle out, quicker the faster the zoom changes; without
  /// [animate], at once. At rest, when the screen leaves the picture's area,
  /// the area follows.
  void camera(
    ml.CameraPosition camera, {
    required double reachDp,
    required bool animate,
  }) {
    final now = _now;
    final zoom = camera.zoom;
    final zoomingIn = zoom > _zoom;
    final dt = now - _cameraAt;
    if (_cameraAt >= 0 && dt > 0 && dt < 250) {
      final instant = (zoom - _zoom).abs() * 1000 / dt;
      _speed = _speed * 0.6 + instant * 0.4;
    } else {
      _speed = 0;
    }
    _cameraAt = now;
    _zoom = zoom;
    _cx = GroupNode.worldX(camera.target.longitude);
    _cy = GroupNode.worldY(camera.target.latitude);
    _reach = (reachDp + 60) / (CapsuleGroups.worldDp * math.pow(2, zoom));
    final shown = _level;
    if (shown == null) return;
    if (_changeLevel(shown, zoom, animate, zoomingIn: zoomingIn)) return;
    if (!_ticker.isActive && _leftCover()) _send();
  }

  bool _leftCover() {
    final cover = _cover;
    if (cover == null) return true;
    final (x, y, r) = cover;
    final dx = _cx - x, dy = _cy - y;
    return math.sqrt(dx * dx + dy * dy) + _reach > r;
  }

  bool _onScreen(GroupNode n) {
    final dx = n.x - _cx, dy = n.y - _cy;
    return dx * dx + dy * dy <= _reach * _reach;
  }

  /// Whether the shown level changed (and the change began).
  bool _changeLevel(
    int shown,
    double zoom,
    bool animate, {
    bool zoomingIn = false,
  }) {
    // A little stickiness, so a pinch resting on a boundary does not flap.
    const sticky = 0.08;
    var next = CapsuleGroups.levelFor(zoom);
    // Out of the heat the bubbles come at the first level shown whole
    // ([firstShown]): switched while still unseen (zoom just under the
    // markers' band), so a whole city of bubbles never splits half seen at
    // 11.5 (157 pieces at once froze the map for a few frames). Zooming
    // out they still gather into their parents there, while they fade.
    if (zoomingIn &&
        next < firstShown &&
        zoom >= MapZoomVisuals.markersFrom - 0.03) {
      next = firstShown;
    }
    if (next > shown && CapsuleGroups.levelFor(zoom - sticky) <= shown) {
      next = shown;
    }
    if (next < shown && CapsuleGroups.levelFor(zoom + sticky) >= shown) {
      next = shown;
    }
    if (next == shown) return false;
    _level = next;
    if (!animate) {
      restart();
      return true;
    }
    _transition = GroupMotion.plan(
      groups,
      from: shown,
      to: next,
      now: _now,
      onScreen: _onScreen,
      centre: (_cx, _cy),
      zoomSpeed: _speed,
      previous: _ticker.isActive ? _transition : null,
    );
    if (MapStats.flashProbe || MapStats.trace) {
      debugPrint(
        'MAPPLAN $_now $shown->$next speed ${_speed.toStringAsFixed(1)} '
        'flights ${_transition.flights.length}',
      );
    }
    if (_transition.isEmpty) {
      restart();
      return true;
    }
    if (!_ticker.isActive) unawaited(_ticker.start());
    _send();
    return true;
  }

  void _tick(Duration _) {
    if (_now >= _transition.end) {
      // Landed: the picture at rest, in the same update as the last frame.
      _ticker.stop();
      _transition = GroupTransition.none;
    }
    _send();
  }

  /// The level the bubbles come out of the heat at.
  static const firstShown = 12;

  /// Sends the picture of now; while one is on its way, the newest is sent
  /// once it has gone (never two in flight, never a frame lost at the end).
  void _send() {
    if (_sending) {
      _dirty = true;
      return;
    }
    unawaited(_sendLoop());
  }

  Future<void> _sendLoop() async {
    final c = controller;
    if (c == null || _level == null) return;
    _sending = true;
    try {
      do {
        _dirty = false;
        seq++;
        final picture = _picture();
        final watch = Stopwatch()..start();
        await _setSource(c, _capsulesSource, picture);
        if (MapStats.trace) {
          debugPrint(
            'MAPSEND $_now features '
            '${(picture['features'] as List).length} '
            '${watch.elapsedMilliseconds}ms',
          );
        }
      } while (_dirty);
    } finally {
      _sending = false;
    }
  }

  Map<String, dynamic> _picture() {
    final level = _level!;
    final transition = _transition;
    final moving = transition.moving;
    final resting = transition.isEmpty;
    // While pieces move, only the screen and a margin: every frame is sent
    // through Android's main thread, which also moves the map (409 pieces
    // took up to 38 ms and froze it for a few frames).
    final (x, y, r) = (_cx, _cy, _reach * (resting ? 3 : 1.15));
    if (resting) _cover = (x, y, r);
    bool near(GroupNode n) {
      final dx = n.x - x, dy = n.y - y;
      return dx * dx + dy * dy <= r * r;
    }

    const probe = MapStats.flashProbe;
    if (probe) sent.clear();
    final features = <Map<String, dynamic>>[];
    final ids = <String>{};
    void add(
      GroupNode n,
      double px,
      double py, {
      int? count,
      double scale = 1,
      double opacity = 1,
    }) {
      if (!ids.add(n.id)) return;
      final feature = _feature(n, px, py, count: count, scale: scale);
      if (probe) feature['properties']['seq'] = seq;
      features.add(feature);
      if (probe) sent[n.id] = (x: px, y: py, opacity: opacity, scale: scale);
    }

    for (final (flight, frame) in transition.frames(_now)) {
      add(
        flight.node,
        frame.x,
        frame.y,
        count: frame.count,
        scale: frame.scale,
        opacity: frame.opacity,
      );
    }
    for (final n in groups.at(level)) {
      if (!moving.contains(n.id) && near(n)) add(n, n.x, n.y);
    }
    for (final n in _posed) {
      add(n, n.x, n.y);
    }
    if (probe) {
      sentBySeq[seq] = Map.of(sent);
      sentBySeq.remove(seq - 60);
    }
    return {'type': 'FeatureCollection', 'features': features};
  }

  /// A piece, kept small (every frame of a split goes through Android's
  /// main thread): id, k (0 pin, 1 bubble), m (its picture), c (a bubble's
  /// number), s (its size, when not 1); 6 decimals (10 cm).
  static Map<String, dynamic> _feature(
    GroupNode n,
    double x,
    double y, {
    int? count,
    double scale = 1,
  }) {
    final shown = count ?? n.count;
    double round(double v) => (v * 1e6).roundToDouble() / 1e6;
    return {
      'type': 'Feature',
      // The tap callback names a feature by this id.
      'id': n.id,
      'properties': {
        'id': n.id,
        'k': n.isBubble ? 1 : 0,
        'm': n.isBubble
            ? 'bubble_${MapLibreImages.bubbleLabel(shown)}'
            : 'pin_${n.color}',
        if (n.isBubble) 'c': shown,
        if (scale != 1) 's': (scale * 1000).roundToDouble() / 1000,
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [
          round(GroupNode.longitudeOf(x)),
          round(GroupNode.latitudeOf(y)),
        ],
      },
    };
  }
}

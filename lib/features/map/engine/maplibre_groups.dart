part of '../map_page.dart';

const _movingSource = 'moving';

/// A GeoJSON source's new data as a string, which MapLibre converts on a
/// worker thread. The plugin's setGeoJsonSource parses it into Java objects
/// on Android's main thread first (tens of milliseconds for a thousand
/// capsules), where the map's own animations and the moving layer run: it
/// held up tap zooms and the split and merge.
Future<void> _setSource(
  ml.MapLibreMapController c,
  String id,
  Map<String, dynamic> data,
) => c.editGeoJsonSource(id, jsonEncode(data));
const _movingPinsLayer = 'moving_pins';
const _movingBubblesLayer = 'moving_bubbles';

/// The MapLibre map's pins and bubbles (mission 2, §2.1): grouped here
/// ([CapsuleGroups]) rather than by the map, so a bubble knows what it splits
/// into. The still ones are one source ([_capsulesSource]); while the shown
/// level changes, the ones that move are another ([_movingSource]), sent
/// every frame ([GroupMotion]). Both are in the map's own space, so they move
/// with it under the fingers. A source update shows at once (no crossfade,
/// checked frame by frame on the phone), so nothing lingers as a ghost.
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
  bool _coverSending = false;
  int _run = 0;

  /// What the still and moving sources hold now (for the flash probe only).
  final sentStill = <String, _Sent>{};
  final sentMoving = <String, _Sent>{};

  /// A split or merge is under way.
  bool get animating => _ticker.isActive;

  // The camera: its zoom, middle and reach (half the screen's diagonal and a
  // margin), in world units.
  double _zoom = 0;
  double _cx = 0;
  double _cy = 0;
  double _reach = 0;

  /// The area the still layer holds (middle and radius, world units): three
  /// times the screen's reach, sent again once the screen leaves it. All of
  /// a level's pins (hundreds) in one update queued the moving frames behind
  /// it on the platform channel; the area keeps it to tens.
  (double, double, double)? _cover;

  /// The level whose pins and bubbles are shown (null before the first
  /// capsules).
  int? get level => _level;

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

  /// New capsules (or a filter): grouped off Flutter's UI thread; the still
  /// layer follows, nothing flies.
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
    await restart();
  }

  /// Everything as it should stand now, no flight (a new style, new data).
  Future<void> restart() async {
    _ticker.stop();
    _transition = GroupTransition.none;
    await _sendStill();
    await _sendMoving(const []);
  }

  /// The camera moved ([reachDp]: half the screen's diagonal). When the
  /// shown level changes, the bubbles split or merge, those on screen moving
  /// from the middle out; without [animate], at once. When the screen leaves
  /// the still layer's area, the area follows.
  void camera(
    ml.CameraPosition camera, {
    required double reachDp,
    required bool animate,
  }) {
    final zoom = camera.zoom;
    _zoom = zoom;
    _cx = GroupNode.worldX(camera.target.longitude);
    _cy = GroupNode.worldY(camera.target.latitude);
    _reach = (reachDp + 60) / (CapsuleGroups.worldDp * math.pow(2, zoom));
    final shown = _level;
    if (shown == null) return;
    if (!_changeLevel(shown, zoom, animate) && !_coverSending && _leftCover()) {
      unawaited(_sendStill());
    }
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
  bool _changeLevel(int shown, double zoom, bool animate) {
    // A little stickiness, so a pinch resting on a boundary does not flap.
    const sticky = 0.08;
    var next = CapsuleGroups.levelFor(zoom);
    if (next > shown && CapsuleGroups.levelFor(zoom - sticky) <= shown) {
      next = shown;
    }
    if (next < shown && CapsuleGroups.levelFor(zoom + sticky) >= shown) {
      next = shown;
    }
    if (next == shown) return false;
    _level = next;
    if (!animate) {
      unawaited(restart());
      return true;
    }
    final now = _now;
    _transition = GroupMotion.plan(
      groups,
      from: shown,
      to: next,
      now: now,
      onScreen: _onScreen,
      centre: (_cx, _cy),
      previous: _ticker.isActive ? _transition : null,
    );
    unawaited(_begin());
    return true;
  }

  /// The moving ones first, then the still ones without them: a piece is
  /// drawn twice for a frame rather than missing for one. The motion starts
  /// with the first frame; the still layer follows.
  Future<void> _begin() async {
    final transition = _transition;
    if (transition.isEmpty) {
      await restart();
      return;
    }
    await _sendMovingAt(_now);
    if (!identical(transition, _transition)) return;
    if (!_ticker.isActive) unawaited(_ticker.start());
    await _sendStill();
  }

  void _tick(Duration _) {
    final now = _now;
    if (now >= _transition.end) {
      _ticker.stop();
      unawaited(_land());
      return;
    }
    // One frame at a time: a frame waits for the one before it.
    if (_sending) return;
    unawaited(_sendMovingAt(now));
  }

  /// All landed: into the still layer, and the moving one emptied once that
  /// is drawn under them.
  Future<void> _land() async {
    final landed = _transition;
    _transition = GroupTransition.none;
    await _sendMovingAt(landed.end, from: landed);
    await _sendStill();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    if (_ticker.isActive || !_transition.isEmpty) return;
    await _sendMoving(const []);
  }

  Future<void> _sendStill() async {
    final c = controller;
    final level = _level;
    if (c == null || level == null) return;
    final moving = _transition.moving;
    final (x, y, r) = (_cx, _cy, _reach * 3);
    _cover = (x, y, r);
    bool near(GroupNode n) {
      final dx = n.x - x, dy = n.y - y;
      return dx * dx + dy * dy <= r * r;
    }

    final still = [
      for (final n in groups.at(level))
        if (!moving.contains(n.id) && near(n)) n,
    ];
    if (MapStats.flashProbe) {
      sentStill
        ..clear()
        ..addAll({
          for (final n in still)
            n.id: (x: n.x, y: n.y, opacity: 1.0, scale: 1.0),
        });
    }
    _coverSending = true;
    try {
      await _setSource(c, _capsulesSource, {
        'type': 'FeatureCollection',
        'features': [for (final n in still) _feature(n, n.x, n.y)],
      });
    } finally {
      _coverSending = false;
    }
  }

  Future<void> _sendMovingAt(int ms, {GroupTransition? from}) {
    final frames = (from ?? _transition).frames(ms).toList();
    if (MapStats.flashProbe) {
      sentMoving
        ..clear()
        ..addAll({
          for (final (flight, f) in frames)
            flight.node.id: (
              x: f.x,
              y: f.y,
              opacity: f.opacity,
              scale: f.scale,
            ),
        });
    }
    return _sendMoving([
      for (final (flight, frame) in frames)
        _feature(
          flight.node,
          frame.x,
          frame.y,
          count: frame.count,
          scale: frame.scale,
          opacity: frame.opacity,
        ),
    ]);
  }

  Future<void> _sendMoving(List<Map<String, dynamic>> features) async {
    final c = controller;
    if (c == null) return;
    if (features.isEmpty) sentMoving.clear();
    _sending = true;
    try {
      await _setSource(c, _movingSource, {
        'type': 'FeatureCollection',
        'features': features,
      });
    } finally {
      _sending = false;
    }
  }

  static Map<String, dynamic> _feature(
    GroupNode n,
    double x,
    double y, {
    int? count,
    double scale = 1,
    double opacity = 1,
  }) {
    final shown = count ?? n.count;
    return {
      'type': 'Feature',
      'id': n.id,
      'properties': {
        'id': n.id,
        'kind': n.isBubble ? 'bubble' : 'pin',
        'image': n.isBubble
            ? 'bubble_${MapLibreImages.bubbleLabel(shown)}'
            : 'pin_${n.color}',
        'count': shown,
        'scale': scale,
        'opacity': opacity,
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [GroupNode.longitudeOf(x), GroupNode.latitudeOf(y)],
      },
    };
  }
}

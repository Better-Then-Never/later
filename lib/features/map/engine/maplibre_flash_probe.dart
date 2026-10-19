part of '../map_page.dart';

/// What was last sent to the map for one marker: where (world units), how
/// strongly it shows (its own opacity, 1 for a still one) and how big.
typedef _Sent = ({double x, double y, double opacity, double scale});

/// The flash probe (`--dart-define=MAP_FLASH=true`, docs/map/FLASH_FIX.md):
/// every frame the map moves or animates, it asks the map which pins and
/// bubbles it drew (queryRenderedFeatures) and compares them with what was
/// sent, counting into MapStats:
/// - a double: the same marker drawn twice in one frame;
/// - a missing one: sent, on screen and visible in the last three probes,
///   but not drawn (a blink);
/// - a ghost: drawn, but in none of the last three probes' sent markers.
/// The three-probe window lets a source update take a frame or two to show.
class _FlashProbe {
  _FlashProbe(this._view);

  final _MapLibreMapViewState _view;
  final _history = <Map<String, _Sent>>[];
  bool _running = false;

  /// Runs until the view goes; probes only while something moves.
  Future<void> run() async {
    if (_running) return;
    _running = true;
    var quietSince = 0;
    final clock = Stopwatch()..start();
    while (_view.mounted) {
      await SchedulerBinding.instance.endOfFrame;
      if (!_view.mounted) break;
      final busy = _view._busy;
      if (busy) quietSince = clock.elapsedMilliseconds;
      // A little after the motion too: a ghost shows once it has ended.
      if (!busy && clock.elapsedMilliseconds - quietSince > 500) {
        _history.clear();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        continue;
      }
      await _probe();
    }
  }

  Future<void> _probe() async {
    final c = _view._controller;
    final camera = c?.cameraPosition;
    if (c == null || camera == null || !_view._styled) return;
    final sent = _view._sentMarkers();
    _history.add(sent);
    if (_history.length > 3) _history.removeAt(0);
    final size = MediaQuery.sizeOf(_view.context);
    final ratio = MediaQuery.devicePixelRatioOf(_view.context);
    final List<dynamic> drawn;
    try {
      drawn = await c.queryRenderedFeaturesInRect(
        Rect.fromLTWH(0, 0, size.width * ratio, size.height * ratio),
        _view._markerLayers,
        null,
      );
    } catch (_) {
      return;
    }
    final counts = <String, int>{};
    var oldest = 1 << 30;
    for (final f in drawn) {
      final properties = (f as Map)['properties'] as Map?;
      final id = properties?['id'];
      if (id is String) counts[id] = (counts[id] ?? 0) + 1;
      final seq = properties?['seq'];
      if (seq is num && seq < oldest) oldest = seq.toInt();
    }
    // How many pictures behind what was sent the drawn one is.
    final behind = oldest == 1 << 30 ? 0 : _view._stage.seq - oldest;
    final selected = _view._shown?.id;
    var doubles = 0;
    for (final MapEntry(:key, :value) in counts.entries) {
      if (value > 1) doubles++;
      if (value > 1) debugPrint('MAPFLASH double $key x$value');
    }
    // On screen with a margin, and clearly visible, in every probe kept.
    final scale = CapsuleGroups.worldDp * math.pow(2, camera.zoom);
    final cx = GroupNode.worldX(camera.target.longitude);
    final cy = GroupNode.worldY(camera.target.latitude);
    final shown = MapZoomVisuals.markerOpacity(camera.zoom);
    bool visible(_Sent s) {
      final dx = (s.x - cx) * scale, dy = (s.y - cy) * scale;
      return dx.abs() < size.width / 2 - 40 &&
          dy.abs() < size.height / 2 - 60 &&
          s.opacity * shown >= 0.3 &&
          s.scale >= 0.3;
    }

    var missing = 0;
    if (_history.length == 3 && camera.bearing.abs() < 0.5) {
      for (final MapEntry(:key, :value) in sent.entries) {
        if (key == selected || counts.containsKey(key)) continue;
        if (!visible(value)) continue;
        if (_history.every((h) => h[key] != null && visible(h[key]!))) {
          missing++;
          debugPrint('MAPFLASH missing $key');
        }
      }
    }
    var ghosts = 0;
    if (_history.length == 3) {
      for (final id in counts.keys) {
        if (id == selected) continue;
        if (_history.every((h) => !h.containsKey(id))) {
          ghosts++;
          debugPrint('MAPFLASH ghost $id');
        }
      }
    }
    if (missing > 0 || ghosts > 0) {
      debugPrint(
        'MAPFLASH frame behind $behind missing $missing ghosts $ghosts',
      );
    }
    MapStats.instance.flashProbed(
      doubles: doubles,
      missing: missing,
      ghosts: ghosts,
    );
  }
}

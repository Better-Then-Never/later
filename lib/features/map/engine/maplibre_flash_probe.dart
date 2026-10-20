part of '../map_page.dart';

/// What was sent to the map for one marker: where (world units), how
/// strongly it shows (1 unless it was sent see-through) and how big.
typedef _Sent = ({double x, double y, double opacity, double scale});

/// The flash probe (`--dart-define=MAP_FLASH=true`, docs/map/FLASH_FIX.md):
/// every frame the map moves or animates, it asks the map which pins and
/// bubbles it drew (queryRenderedFeatures) and compares them with the very
/// picture it drew (every feature carries its picture's number; the map may
/// be a few pictures behind the newest sent), counting into MapStats:
/// - a double: the same marker drawn twice in one frame;
/// - a missing one: in the picture, on screen and clearly visible, but not
///   drawn (a blink);
/// - a ghost: drawn, but not in the picture drawn (a leftover);
/// - a torn frame: parts of the map drawing different pictures (a source
///   re-tiled tile by tile).
class _FlashProbe {
  _FlashProbe(this._view);

  final _MapLibreMapViewState _view;
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
    final seqs = <int>{};
    for (final f in drawn) {
      final properties = (f as Map)['properties'] as Map?;
      final id = properties?['id'];
      if (id is String) counts[id] = (counts[id] ?? 0) + 1;
      final seq = properties?['seq'];
      if (seq is num) seqs.add(seq.toInt());
    }
    var doubles = 0;
    for (final MapEntry(:key, :value) in counts.entries) {
      if (value > 1) {
        doubles++;
        debugPrint('MAPFLASH double $key x$value');
      }
    }
    final torn = seqs.length > 1;
    if (torn) debugPrint('MAPFLASH torn ${seqs.toList()..sort()}');
    // The picture drawn (the newest, when torn).
    final seq = seqs.isEmpty ? _view._stage.seq : seqs.reduce(math.max);
    final picture = _view._stage.sentBySeq[seq];
    var missing = 0;
    var ghosts = 0;
    if (picture != null && camera.bearing.abs() < 0.5) {
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

      for (final MapEntry(:key, :value) in picture.entries) {
        if (counts.containsKey(key) || !visible(value)) continue;
        missing++;
        debugPrint('MAPFLASH missing $key (picture $seq)');
      }
      for (final id in counts.keys) {
        if (picture.containsKey(id)) continue;
        ghosts++;
        debugPrint('MAPFLASH ghost $id (picture $seq)');
      }
    }
    MapStats.instance.flashProbed(
      doubles: doubles,
      missing: missing,
      ghosts: ghosts,
      torn: torn,
      behind: _view._stage.seq - seq,
    );
  }
}

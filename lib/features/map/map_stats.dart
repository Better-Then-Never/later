import 'dart:convert';
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/theme/app_colors.dart';

/// What the map does, counted for measuring (docs/map/PERFORMANCE.md): how
/// often the heat layer is created, changed or emptied, how many markers each
/// update adds, removes or changes, how often the map widget is rebuilt and
/// restyled, camera events, clustering time and heat tiles drawn.
///
/// Off in release builds. Each finger gesture on the map is summed up in one
/// log line (`MAPSTATS {...}`); the perf test reads [total] after a flow.
class MapStats {
  MapStats._();

  static final instance = MapStats._();

  static const enabled = !kReleaseMode;

  /// The recording strip ([MapHarnessStrip]) shows only for the gesture
  /// harness (tool/dev/map_gesture.sh).
  static const harness = bool.fromEnvironment('MAP_HARNESS');

  /// Whether the map is moving or under a finger: frames are only judged
  /// then (a still map draws nothing, and that is no stall).
  final active = ValueNotifier<bool>(false);

  bool _timing = false;
  int? _lastVsync;

  /// Starts judging Flutter's frames (once).
  void watchFrames() {
    if (!enabled || _timing) return;
    _timing = true;
    SchedulerBinding.instance.addTimingsCallback(_frames);
    active.addListener(() {
      if (!active.value) _lastVsync = null;
    });
  }

  void _frames(List<FrameTiming> timings) {
    if (!active.value) return;
    for (final t in timings) {
      final vsync = t.timestampInMicroseconds(FramePhase.vsyncStart);
      final last = _lastVsync;
      _lastVsync = vsync;
      final build = t.buildDuration.inMicroseconds;
      final raster = t.rasterDuration.inMicroseconds;
      _count((c) {
        c.activeFrames++;
        // 120 Hz: 8.3 ms a frame.
        if (build > 8333 || raster > 8333) c.jankyFrames++;
        final worst = build > raster ? build : raster;
        if (worst > c.worstFrameUs) c.worstFrameUs = worst;
        if (last != null) {
          final gap = vsync - last;
          if (gap >= 100000) c.frameGaps100++;
          if (gap > c.longestGapUs) c.longestGapUs = gap;
        }
      });
    }
  }

  final total = _Counts();
  _Counts? _gesture;

  /// Moves the map's camera at once (registered by the map page; for the
  /// perf test, so every run starts from the same view).
  Future<void> Function(LatLng target, double zoom)? moveCamera;

  Set<Marker>? _lastMarkers;
  Set<TileOverlay>? _lastTiles;
  String? _lastStyle;

  /// The map widget was built with these layers.
  void built({
    required Set<Marker> markers,
    required Set<TileOverlay> tiles,
    required String? style,
  }) {
    if (!enabled) return;
    _count((c) => c.mapBuilds++);
    final last = _lastMarkers;
    if (last != null && !identical(last, markers)) {
      final before = {for (final m in last) m.markerId: m};
      final after = {for (final m in markers) m.markerId: m};
      var added = 0, removed = 0, changed = 0;
      for (final MapEntry(:key, :value) in after.entries) {
        final old = before[key];
        if (old == null) {
          added++;
        } else if (old != value) {
          changed++;
        }
      }
      for (final key in before.keys) {
        if (!after.containsKey(key)) removed++;
      }
      if (added + removed + changed > 0) {
        _count((c) {
          c.markerUpdates++;
          c.markersAdded += added;
          c.markersRemoved += removed;
          c.markersChanged += changed;
          if (added + removed + changed > c.largestMarkerUpdate) {
            c.largestMarkerUpdate = added + removed + changed;
          }
        });
      }
    }
    _lastMarkers = markers;
    final lastTiles = _lastTiles;
    if (lastTiles != null && !setEquals(lastTiles, tiles)) {
      final ids = {for (final t in tiles) t.tileOverlayId};
      final lastIds = {for (final t in lastTiles) t.tileOverlayId};
      _count((c) {
        if (!setEquals(ids, lastIds)) {
          c.heatCreatedOrRemoved++;
        } else {
          c.heatChanged++;
        }
      });
    }
    _lastTiles = tiles;
    if (_lastStyle != null && style != _lastStyle) {
      _count((c) => c.styleChanges++);
    }
    _lastStyle = style;
  }

  /// The heat layer's tiles were thrown away (the map draws them again).
  void heatCleared() => _count((c) => c.heatCleared++);

  /// A heat tile was asked for and drawn in [ms] (empty: none to draw).
  void heatTile(int ms, {required bool empty}) => _count((c) {
    c.heatTiles++;
    if (empty) c.heatTilesEmpty++;
    c.heatTileMs += ms;
  });

  /// How long the map took to answer a finger: from the first touch of a
  /// gesture to its first camera move.
  final _sinceDown = Stopwatch();
  bool _answered = true;

  void cameraMoved() => _count((c) {
    c.cameraMoves++;
    if (!_answered) {
      _answered = true;
      final ms = _sinceDown.elapsedMilliseconds;
      c.answers++;
      c.answerMs += ms;
      if (ms > c.slowestAnswerMs) c.slowestAnswerMs = ms;
    }
  });
  void cameraIdle() => _count((c) => c.cameraIdles++);

  /// The capsules were grouped for the screen in [us] microseconds.
  void clustered(int us) => _count((c) {
    c.clusterings++;
    c.clusterUs += us;
    if (us > c.slowestClusterUs) c.slowestClusterUs = us;
  });

  void gestureStarted() {
    _sinceDown
      ..reset()
      ..start();
    _answered = false;
    if (!enabled) return;
    _gesture = _Counts();
  }

  void gestureEnded() {
    final g = _gesture;
    if (!enabled || g == null) return;
    _gesture = null;
    total.gestures++;
    debugPrint('MAPSTATS ${jsonEncode(g.toJson())}');
  }

  void reset() {
    if (!enabled) return;
    total.clear();
  }

  void _count(void Function(_Counts) f) {
    if (!enabled) return;
    f(total);
    final g = _gesture;
    if (g != null) f(g);
  }
}

class _Counts {
  int gestures = 0;
  int mapBuilds = 0;
  int markerUpdates = 0;
  int markersAdded = 0;
  int markersRemoved = 0;
  int markersChanged = 0;
  int largestMarkerUpdate = 0;
  int heatCreatedOrRemoved = 0;
  int heatChanged = 0;
  int heatCleared = 0;
  int heatTiles = 0;
  int heatTilesEmpty = 0;
  int heatTileMs = 0;
  int styleChanges = 0;
  int cameraMoves = 0;
  int cameraIdles = 0;
  int clusterings = 0;
  int clusterUs = 0;
  int slowestClusterUs = 0;
  int activeFrames = 0;
  int jankyFrames = 0;
  int worstFrameUs = 0;
  int frameGaps100 = 0;
  int longestGapUs = 0;
  int answers = 0;
  int answerMs = 0;
  int slowestAnswerMs = 0;

  /// Every change to the heat layer that can make it disappear or redraw.
  int get heatMutations => heatCreatedOrRemoved + heatChanged + heatCleared;

  void clear() {
    gestures = mapBuilds = markerUpdates = markersAdded = markersRemoved = 0;
    markersChanged = largestMarkerUpdate = heatCreatedOrRemoved = 0;
    heatChanged = heatCleared = heatTiles = heatTilesEmpty = heatTileMs = 0;
    styleChanges = cameraMoves = cameraIdles = clusterings = clusterUs = 0;
    slowestClusterUs = activeFrames = jankyFrames = worstFrameUs = 0;
    frameGaps100 = longestGapUs = answers = answerMs = slowestAnswerMs = 0;
  }

  Map<String, int> toJson() => {
    'gestures': gestures,
    'map_builds': mapBuilds,
    'marker_updates': markerUpdates,
    'markers_added': markersAdded,
    'markers_removed': markersRemoved,
    'markers_changed': markersChanged,
    'largest_marker_update': largestMarkerUpdate,
    'heat_mutations': heatMutations,
    'heat_created_or_removed': heatCreatedOrRemoved,
    'heat_changed': heatChanged,
    'heat_cleared': heatCleared,
    'heat_tiles': heatTiles,
    'heat_tiles_empty': heatTilesEmpty,
    'heat_tile_ms': heatTileMs,
    'style_changes': styleChanges,
    'camera_moves': cameraMoves,
    'camera_idles': cameraIdles,
    'clusterings': clusterings,
    'cluster_ms': clusterUs ~/ 1000,
    'slowest_cluster_us': slowestClusterUs,
    'active_frames': activeFrames,
    'janky_frames': jankyFrames,
    'janky_permille': activeFrames == 0
        ? 0
        : jankyFrames * 1000 ~/ activeFrames,
    'worst_frame_us': worstFrameUs,
    'frame_gaps_100ms': frameGaps100,
    'longest_gap_ms': longestGapUs ~/ 1000,
    'answer_ms': answers == 0 ? 0 : answerMs ~/ answers,
    'slowest_answer_ms': slowestAnswerMs,
  };
}

/// For the gesture harness only ([MapStats.harness]): two small blocks in the
/// top corner the screen recording reads. The first changes shade on every
/// frame while the map is active (so a recording tells a stalled app from a
/// still map), the second is red while it is active.
class MapHarnessStrip extends StatefulWidget {
  const MapHarnessStrip({super.key});

  @override
  State<MapHarnessStrip> createState() => _MapHarnessStripState();
}

class _MapHarnessStripState extends State<MapHarnessStrip>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => setState(() => _tick++));
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    MapStats.instance.active.addListener(_sync);
  }

  void _sync() {
    final active = MapStats.instance.active.value;
    if (active && !_ticker.isActive) _ticker.start();
    if (!active && _ticker.isActive) _ticker.stop();
    setState(() {});
  }

  @override
  void dispose() {
    MapStats.instance.active.removeListener(_sync);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = MapStats.instance.active.value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: 10,
          child: ColoredBox(
            color: _tick.isEven ? AppColors.mediaBlack : AppColors.onMedia,
          ),
        ),
        SizedBox.square(
          dimension: 10,
          child: ColoredBox(
            color: active ? AppColors.danger : AppColors.infoBlue,
          ),
        ),
      ],
    );
  }
}

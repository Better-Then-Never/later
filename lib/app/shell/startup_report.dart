import 'dart:async';
import 'dart:developer';
import 'dart:ui' show FramePhase;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// The cold start, measured (docs/map/COLD_START.md). Named moments go to
/// the device log as `LATERSTART <name>` (debug and profile builds; the
/// launcher script `tool/dev/coldstart.sh` times them from Android's own
/// launch), and Android is told when the map has drawn its pins
/// (`Activity.reportFullyDrawn`): "time to full display" in Android vitals,
/// logcat "Fully drawn". Once per process; Android ignores repeats anyway.
abstract final class StartupReport {
  static const _channel = MethodChannel('later.app/startup');
  static bool _reported = false;
  static final _marked = <String>{};

  /// Frames from the first one until shortly after the map is full.
  static final _frames = <FrameTiming>[];
  static bool _watching = false;

  /// The start begins (bootstrap, binding ready): its first mark, and its
  /// frames are counted from here.
  static void begin() {
    _began = Timeline.now;
    mark('dart');
    _watchFrames();
  }

  /// When [begin] ran, on the frames' clock (microseconds).
  static int _began = 0;

  /// A named moment of this start, once per process.
  static void mark(String name) {
    if (kReleaseMode || !_marked.add(name)) return;
    Timeline.instantSync('later.start.$name');
    debugPrint('LATERSTART $name');
  }

  /// The signed-in home screen drew its first frame.
  static void homeDrawn() => mark('home');

  /// The map shows everything it has for this start: the streets and every
  /// pin (TTFD).
  static void fullyDrawn() {
    if (_reported) return;
    _reported = true;
    mark('full');
    unawaited(
      _channel.invokeMethod<void>('fullyDrawn').catchError((Object _) {
        // Platforms without the channel (tests, iOS): nothing to report to.
      }),
    );
    if (_watching) {
      // The reveal runs after it: the frames of the next two seconds count.
      Timer(const Duration(seconds: 2), _reportFrames);
    }
  }

  static void _watchFrames() {
    if (_watching || kReleaseMode) return;
    _watching = true;
    SchedulerBinding.instance.addTimingsCallback(_frames.addAll);
  }

  static void _reportFrames() {
    SchedulerBinding.instance.removeTimingsCallback(_frames.addAll);
    // Janky at 120 Hz: build or raster over 8.3 ms (docs/feel/RIG.md).
    var over8 = 0, over16 = 0, worst = 0;
    for (final f in _frames) {
      final ms = [
        f.buildDuration.inMicroseconds,
        f.rasterDuration.inMicroseconds,
      ].reduce((a, b) => a > b ? a : b);
      if (ms > 8333) over8++;
      if (ms > 16667) over16++;
      if (ms > worst) worst = ms;
    }
    // The slowest, as ms after "dart": build/raster ms.
    final slow =
        _frames
            .where(
              (f) =>
                  f.buildDuration.inMicroseconds > 8333 ||
                  f.rasterDuration.inMicroseconds > 8333,
            )
            .toList()
          ..sort((a, b) => b.totalSpan.compareTo(a.totalSpan));
    String ms(Duration d) => (d.inMicroseconds / 1000).toStringAsFixed(0);
    final at = [
      for (final f in slow.take(8))
        '${((f.timestampInMicroseconds(FramePhase.vsyncStart) - _began) / 1000).round()}'
            ':${ms(f.buildDuration)}/${ms(f.rasterDuration)}',
    ].join(',');
    debugPrint(
      'LATERSTART frames n=${_frames.length} over8=$over8 over16=$over16 '
      'worst=${(worst / 1000).toStringAsFixed(1)} slow=$at',
    );
    _frames.clear();
  }
}

import 'dart:developer';

import 'package:flutter/scheduler.dart';

/// Named moments in the profile-mode timeline (tap, shutter feedback, first
/// frame of a page), which test_driver/perf_driver.dart turns into "tap → X"
/// durations for docs/feel/PERFORMANCE.md. The timeline is off in release
/// builds, where these cost a flag check.
abstract final class PerfMarks {
  /// Marks this moment.
  static void now(String name) => Timeline.instantSync('later.$name');

  /// Marks the end of the next frame's build (its raster follows within one
  /// frame).
  static void nextFrame(String name) =>
      SchedulerBinding.instance.addPostFrameCallback((_) => now(name));
}

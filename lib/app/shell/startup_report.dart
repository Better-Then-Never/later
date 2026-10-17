import 'dart:async';

import 'package:flutter/services.dart';

/// Tells Android when the signed-in home screen first drew
/// (`Activity.reportFullyDrawn`): "time to full display" in Android vitals,
/// and the cold start number in docs/feel/PERFORMANCE.md (logcat
/// "Fully drawn"). Once per process; Android ignores repeats anyway.
abstract final class StartupReport {
  static const _channel = MethodChannel('later.app/startup');
  static bool _reported = false;

  static void homeDrawn() {
    if (_reported) return;
    _reported = true;
    unawaited(
      _channel.invokeMethod<void>('fullyDrawn').catchError((Object _) {
        // Platforms without the channel (tests, iOS): nothing to report to.
      }),
    );
  }
}

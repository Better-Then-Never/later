// Driver for integration_test/perf_test.dart: turns each traced flow into
// build/<flow>.timeline_summary.json (see docs/ux/PERFORMANCE.md).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final numbers = <String, Object?>{};
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        final timeline = driver.Timeline.fromJson(value);
        final summary = driver.TimelineSummary.summarize(timeline);
        try {
          await summary.writeTimelineToFile(
            entry.key,
            pretty: true,
            includeSummary: true,
          );
        } on StateError catch (e) {
          // A flow that drew no frame (e.g. no chat to open for this
          // account) is reported instead of ending the run.
          stderr.writeln('${entry.key}: no frames ($e)');
        }
      } else {
        numbers[entry.key] = value;
      }
    }
    await File(
      'build/perf_numbers.json',
    ).writeAsString(const JsonEncoder.withIndent('  ').convert(numbers));
  },
);

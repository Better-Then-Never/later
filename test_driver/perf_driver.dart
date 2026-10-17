// Driver for integration_test/perf_test.dart: turns each traced flow into
// build/<flow>.timeline_summary.json (see docs/feel/PERFORMANCE.md), and
// the PerfMarks in its timeline into "tap → mark" durations in
// build/perf_numbers.json (e.g. chat_open.chat.messagesShown_ms).
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
        _marks(entry.key, timeline, numbers);
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

/// Milliseconds from each `later.tap` (marked by the test) to the marks that
/// follow it, as lists per flow and mark.
void _marks(String flow, driver.Timeline timeline, Map<String, Object?> out) {
  final events = [
    for (final e in timeline.events ?? const <driver.TimelineEvent>[])
      if ((e.name ?? '').startsWith('later.') && e.timestampMicros != null) e,
  ]..sort((a, b) => a.timestampMicros!.compareTo(b.timestampMicros!));
  int? tap;
  final seen = <String>{};
  for (final e in events) {
    final name = e.name!.substring('later.'.length);
    if (name == 'tap') {
      tap = e.timestampMicros;
      seen.clear();
      continue;
    }
    // Only the first of each mark after a tap counts.
    if (tap == null || !seen.add(name)) continue;
    final key = '$flow.${name}_ms';
    final list = (out[key] as List<Object?>?) ?? <Object?>[];
    list.add(((e.timestampMicros! - tap) / 1000).round());
    out[key] = list;
  }
}

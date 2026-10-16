// Markdown table of the frame timings recorded by integration_test/perf_test.dart.
//
//   dart run tool/perf_table.dart docs/ux/perf/baseline
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final dir = Directory(args.isEmpty ? 'build' : args.first);
  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.timeline_summary.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  String ms(Object? v) => v is num ? v.toStringAsFixed(1) : '-';
  stdout.writeln(
    '| Flow | Frames | Build avg / p90 / worst (ms) | Raster avg / p90 / worst (ms) | Over 16.7 ms (build / raster) |',
  );
  stdout.writeln('|---|---|---|---|---|');
  for (final f in files) {
    final s = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    final name = f.uri.pathSegments.last.replaceAll(
      '.timeline_summary.json',
      '',
    );
    final frames = s['frame_count'];
    final missedBuild = s['missed_frame_build_budget_count'];
    final missedRaster = s['missed_frame_rasterizer_budget_count'];
    stdout.writeln(
      '| $name | $frames '
      '| ${ms(s['average_frame_build_time_millis'])} / '
      '${ms(s['90th_percentile_frame_build_time_millis'])} / '
      '${ms(s['worst_frame_build_time_millis'])} '
      '| ${ms(s['average_frame_rasterizer_time_millis'])} / '
      '${ms(s['90th_percentile_frame_rasterizer_time_millis'])} / '
      '${ms(s['worst_frame_rasterizer_time_millis'])} '
      '| $missedBuild / $missedRaster |',
    );
  }
  final numbers = File('${dir.path}/perf_numbers.json');
  if (numbers.existsSync()) stdout.writeln('\n${numbers.readAsStringSync()}');
}

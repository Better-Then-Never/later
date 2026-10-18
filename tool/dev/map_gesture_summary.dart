// One table for the map gesture check (tool/dev/map_gesture.sh): per flow and
// run, Flutter's frames (timeline), the map's own counts (MapStats, from
// perf_numbers.json) and the recording's report (map_gesture_report.py).
//
//   dart run tool/dev/map_gesture_summary.dart build/perf/<label>
import 'dart:convert';
import 'dart:io';

const _budgetUs = 8333; // 120 Hz
const _flows = ['map_pinch_sweep', 'map_pinch_wave'];

void main(List<String> args) {
  final dir = Directory(args.isEmpty ? 'build/perf' : args.first);
  final runs =
      dir
          .listSync()
          .whereType<Directory>()
          .where(
            (d) => d.uri.pathSegments.reversed.elementAt(1).startsWith('run_'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final columns = [
    'run',
    'frames',
    'janky %',
    'worst ms',
    '>16.7 ms',
    'heat mut.',
    'heat tiles',
    'marker upd.',
    'markers +/-/~',
    'largest upd.',
    'in-app gaps ≥100',
    'longest gap ms',
    'video gaps ≥100',
    'video longest ms',
    'frozen ≥150',
    'dropout frames',
    'heat blinks',
  ];
  for (final flow in _flows) {
    stdout.writeln('\n### $flow\n');
    stdout.writeln('| ${columns.join(' | ')} |');
    stdout.writeln('|${List.filled(columns.length, '---').join('|')}|');
    for (final run in runs) {
      final name = run.uri.pathSegments.reversed.elementAt(1);
      final cells = <String>[name];
      final summary = File('${run.path}/$flow.timeline_summary.json');
      if (summary.existsSync()) {
        final s = jsonDecode(summary.readAsStringSync()) as Map;
        final build = (s['frame_build_times'] as List).cast<num>();
        final raster = (s['frame_rasterizer_times'] as List).cast<num>();
        final n = build.length < raster.length ? build.length : raster.length;
        var janky = 0, over = 0;
        num worst = 0;
        for (var i = 0; i < n; i++) {
          final w = build[i] > raster[i] ? build[i] : raster[i];
          if (w > _budgetUs) janky++;
          if (w > 16667) over++;
          if (w > worst) worst = w;
        }
        cells.addAll([
          '$n',
          (n == 0 ? 0 : janky * 100 / n).toStringAsFixed(1),
          (worst / 1000).toStringAsFixed(1),
          '$over',
        ]);
      } else {
        cells.addAll(['-', '-', '-', '-']);
      }
      final numbers = File('${run.path}/perf_numbers.json');
      final stats = numbers.existsSync()
          ? jsonDecode(numbers.readAsStringSync()) as Map
          : const {};
      String stat(String key) {
        final v = stats['${flow}_$key'];
        return v is List && v.isNotEmpty ? '${v.last}' : '-';
      }

      cells.addAll([
        stat('heat_mutations'),
        stat('heat_tiles'),
        stat('marker_updates'),
        '${stat('markers_added')}/${stat('markers_removed')}/${stat('markers_changed')}',
        stat('largest_marker_update'),
        stat('frame_gaps_100ms'),
        stat('longest_gap_ms'),
      ]);
      final report = File('${run.path}/$flow.report.json');
      if (report.existsSync()) {
        final r = jsonDecode(report.readAsStringSync()) as Map;
        cells.addAll([
          '${r['gaps_100ms']}',
          '${r['longest_gap_ms']}',
          '${r['frozen_150ms']}',
          '${r['dropout_frames']}',
          '${r['heat_blinks']}',
        ]);
      } else {
        cells.addAll(['-', '-', '-', '-', '-']);
      }
      stdout.writeln('| ${cells.join(' | ')} |');
    }
  }
}

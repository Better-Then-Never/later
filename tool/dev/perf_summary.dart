// Summary of the runs recorded by tool/dev/perf.sh, judged against a
// 120 Hz frame budget (8.33 ms; the phone's refresh rate, docs/feel/DEVICE.md).
//
//   dart run tool/dev/perf_summary.dart build/perf/<label> [budget_ms]
//
// A frame is janky when its build or its raster took longer than the budget
// (the UI and raster threads are pipelined, so each has one vsync). Per flow
// it prints the median over runs of: frames, janky %, worst frame, and the
// p90 of max(build, raster). Below that, the timestamps the test measured
// (perf_numbers.json, including each flow's wall time) and the stalls of
// Android's main thread per run: Flutter's vsync comes from that thread, so
// while it is stalled the app draws nothing (a freeze no frame time shows).
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('usage: perf_summary.dart <dir> [budget_ms]');
    exit(64);
  }
  final root = Directory(args.first);
  final budgetMs = args.length > 1 ? double.parse(args[1]) : 1000 / 120;
  final runs =
      root
          .listSync()
          .whereType<Directory>()
          .where(
            (d) => d.uri.pathSegments.reversed.skip(1).first.startsWith('run_'),
          )
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  if (runs.isEmpty) {
    stderr.writeln('no run_* folders in ${root.path}');
    exit(1);
  }

  final flows = <String, List<_Flow>>{};
  final numbers = <String, List<num>>{};
  final android = <String>[];
  for (final run in runs) {
    for (final f in run.listSync().whereType<File>()) {
      final name = f.uri.pathSegments.last;
      if (name.endsWith('.timeline_summary.json')) {
        final flow = name.replaceAll('.timeline_summary.json', '');
        final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        flows.putIfAbsent(flow, () => []).add(_Flow.of(json, budgetMs));
      } else if (name == 'perf_numbers.json') {
        final json = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        json.forEach((k, v) {
          if (v is num) numbers.putIfAbsent(k, () => []).add(v);
          if (v is List) {
            numbers.putIfAbsent(k, () => []).addAll(v.whereType<num>());
          }
        });
      } else if (name == 'drive.log') {
        android.add(
          '${run.uri.pathSegments.reversed.skip(1).first}: '
          '${_stalls(f.readAsStringSync())}',
        );
      }
    }
  }

  String ms(num v) => v.toStringAsFixed(1);
  stdout.writeln(
    'Budget ${ms(budgetMs)} ms, ${runs.length} run(s); medians over runs.\n',
  );
  stdout.writeln(
    '| Flow | Frames | Janky % | Worst frame (ms) | p90 frame (ms) | Janky % per run |',
  );
  stdout.writeln('|---|---|---|---|---|---|');
  for (final e
      in flows.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
    final r = e.value;
    stdout.writeln(
      '| ${e.key} '
      '| ${_median(r.map((f) => f.frames)).round()} '
      '| ${ms(_median(r.map((f) => f.jankyPercent)))} '
      '| ${ms(_median(r.map((f) => f.worstMs)))} '
      '| ${ms(_median(r.map((f) => f.p90Ms)))} '
      '| ${r.map((f) => ms(f.jankyPercent)).join(' / ')} |',
    );
  }
  if (numbers.isNotEmpty) {
    stdout.writeln('\n| Measured | Median | All |');
    stdout.writeln('|---|---|---|');
    for (final e
        in numbers.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
      stdout.writeln(
        '| ${e.key} | ${_median(e.value).round()} | ${e.value.join(', ')} |',
      );
    }
  }
  if (android.isNotEmpty) {
    stdout.writeln(
      '\nAndroid main-thread stalls (Choreographer "Skipped N frames", whole '
      'run; Flutter gets no vsync meanwhile, so nothing moves):',
    );
    android.forEach(stdout.writeln);
  }
}

class _Flow {
  _Flow(this.frames, this.jankyPercent, this.worstMs, this.p90Ms);

  factory _Flow.of(Map<String, dynamic> json, double budgetMs) {
    List<double> list(String key) => [
      for (final v in (json[key] as List? ?? const [])) (v as num) / 1000,
    ];
    final build = list('frame_build_times');
    final raster = list('frame_rasterizer_times');
    final n = build.length < raster.length ? build.length : raster.length;
    final worst = [
      for (var i = 0; i < n; i++) build[i] > raster[i] ? build[i] : raster[i],
    ];
    final janky = worst.where((t) => t > budgetMs).length;
    final sorted = [...worst]..sort();
    return _Flow(
      n,
      n == 0 ? 0 : 100 * janky / n,
      sorted.isEmpty ? 0 : sorted.last,
      sorted.isEmpty ? 0 : sorted[((sorted.length - 1) * 0.9).round()],
    );
  }

  final int frames;
  final double jankyPercent;
  final double worstMs;
  final double p90Ms;
}

double _median(Iterable<num> values) {
  final s = values.map((v) => v.toDouble()).toList()..sort();
  if (s.isEmpty) return 0;
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
}

/// Main-thread stalls in a run's log: Android reports each time its main
/// thread missed 30 or more frames.
String _stalls(String log) {
  final skipped = [
    for (final m in RegExp(r'Skipped (\d+) frames').allMatches(log))
      int.parse(m.group(1)!),
  ];
  if (skipped.isEmpty) return 'none';
  final total = skipped.fold<int>(0, (a, b) => a + b);
  final longest = skipped.reduce((a, b) => a > b ? a : b);
  return '${skipped.length} stalls, $total frames in all, longest $longest '
      '(~${(longest / 120).toStringAsFixed(1)} s at 120 Hz): '
      '${skipped.join(', ')}';
}

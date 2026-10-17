// What the slowest frames of a flow spent their time on, from a full
// timeline kept by `KEEP_TIMELINE=1 tool/dev/perf.sh` (best with
// `DETAIL=1`, which adds an event per widget build, layout and paint).
//
//   dart run tool/dev/slow_frames.dart <flow.timeline.json> [frames] [budget_ms]
//
// For each frame over the budget (8.33 ms by default; the N slowest) it
// prints the UI-thread or raster-thread span and the longest events nested
// in it, so the cause has a name (a widget's first build, a layout pass,
// an image decode, a raster pass) instead of a guess.
import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: slow_frames.dart <flow.timeline.json> [frames] [budget_ms]',
    );
    exit(64);
  }
  final limit = args.length > 1 ? int.parse(args[1]) : 8;
  final budgetUs =
      ((args.length > 2 ? double.parse(args[2]) : 1000 / 120) * 1000).round();
  final json = jsonDecode(File(args.first).readAsStringSync());
  final raw = (json is Map ? json['traceEvents'] : json) as List;

  // Complete events from 'X' and from matching 'B'/'E' pairs per thread.
  final spans = <_Span>[];
  final open = <String, List<Map<String, dynamic>>>{};
  for (final e in raw.cast<Map<String, dynamic>>()) {
    final ph = e['ph'];
    final tid = '${e['tid']}';
    if (ph == 'X' && e['dur'] != null) {
      spans.add(
        _Span(e['name'] as String, tid, e['ts'] as int, e['dur'] as int),
      );
    } else if (ph == 'B') {
      open.putIfAbsent(tid, () => []).add(e);
    } else if (ph == 'E') {
      final stack = open[tid];
      if (stack == null || stack.isEmpty) continue;
      final b = stack.removeLast();
      spans.add(
        _Span(
          b['name'] as String,
          tid,
          b['ts'] as int,
          (e['ts'] as int) - (b['ts'] as int),
        ),
      );
    }
  }
  spans.sort((a, b) => a.start.compareTo(b.start));

  // Frame roots: the UI thread's frame and the raster thread's draw.
  const roots = {
    'Animator::BeginFrame',
    'GPURasterizer::Draw',
    'Rasterizer::DoDraw',
  };
  final frames =
      spans.where((s) => roots.contains(s.name) && s.dur > budgetUs).toList()
        ..sort((a, b) => b.dur.compareTo(a.dur));
  final first = spans.isEmpty ? 0 : spans.first.start;
  stdout.writeln(
    '${frames.length} frame span(s) over ${(budgetUs / 1000).toStringAsFixed(2)} ms; '
    'the ${limit < frames.length ? limit : frames.length} slowest:\n',
  );
  for (final f in frames.take(limit)) {
    stdout.writeln(
      '${f.name} at +${((f.start - first) / 1000).round()} ms: '
      '${(f.dur / 1000).toStringAsFixed(1)} ms',
    );
    final inside =
        spans
            .where(
              (s) =>
                  s.tid == f.tid &&
                  s != f &&
                  s.start >= f.start &&
                  s.start + s.dur <= f.start + f.dur,
            )
            .toList()
          ..sort(
            (a, b) => a.start != b.start
                ? a.start.compareTo(b.start)
                : b.dur.compareTo(a.dur),
          );
    // Self time: an event's duration minus that of the events directly
    // inside it, so the cost lands on the leaf that spent it.
    final self = <_Span, int>{for (final s in inside) s: s.dur};
    final stack = <_Span>[];
    for (final s in inside) {
      while (stack.isNotEmpty && stack.last.start + stack.last.dur <= s.start) {
        stack.removeLast();
      }
      if (stack.isNotEmpty) self[stack.last] = self[stack.last]! - s.dur;
      stack.add(s);
    }
    final byName = <String, int>{};
    final counts = <String, int>{};
    for (final e in self.entries) {
      byName[e.key.name] = (byName[e.key.name] ?? 0) + e.value;
      counts[e.key.name] = (counts[e.key.name] ?? 0) + 1;
    }
    final phases = [
      for (final name in const [
        'BUILD',
        'LAYOUT',
        'PAINT',
        'SEMANTICS',
        'COMPOSITING',
        'FINALIZE TREE',
      ])
        if (inside.any((s) => s.name == name))
          '$name ${(inside.where((s) => s.name == name).fold<int>(0, (t, s) => t + s.dur) / 1000).toStringAsFixed(1)}',
    ];
    if (phases.isNotEmpty)
      stdout.writeln('    phases: ${phases.join(', ')} ms');
    final top = byName.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in top.take(12)) {
      stdout.writeln(
        '    ${(e.value / 1000).toStringAsFixed(1).padLeft(6)} ms self  '
        '${e.key}${counts[e.key]! > 1 ? ' ×${counts[e.key]}' : ''}',
      );
    }
    stdout.writeln();
  }
}

class _Span {
  _Span(this.name, this.tid, this.start, this.dur);
  final String name;
  final String tid;
  final int start;
  final int dur;
}

// Builds lib/l10n/app_<lang>.arb from the per-area fragments:
//
//   tool/l10n/fragments/<area>/en.json   (template: values + "@key" metadata)
//   tool/l10n/fragments/<area>/<lang>.json (translations: values only)
//
// Areas keep parallel work conflict-free (one folder per feature); keys must be
// unique across areas. Then `flutter gen-l10n` (run by `flutter pub get` /
// builds, `generate: true`) produces AppLocalizations.
//
//   dart run tool/l10n/build_arb.dart          # write the ARB files
//   dart run tool/l10n/build_arb.dart --check  # fail if they are out of date
import 'dart:convert';
import 'dart:io';

const languages = ['en', 'ru', 'pl', 'de', 'es'];

void main(List<String> args) {
  final check = args.contains('--check');
  final root = Directory('tool/l10n/fragments');
  final areas = root.listSync().whereType<Directory>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final owner = <String, String>{};
  var stale = false;
  var problems = 0;

  for (final lang in languages) {
    final merged = <String, Object?>{'@@locale': lang};
    for (final area in areas) {
      final name = area.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final file = File('${area.path}/$lang.json');
      if (!file.existsSync()) continue;
      final Map<String, Object?> data;
      try {
        data = (jsonDecode(file.readAsStringSync()) as Map)
            .cast<String, Object?>();
      } on FormatException catch (e) {
        stderr.writeln('${file.path}: invalid JSON: $e');
        problems++;
        continue;
      }
      for (final entry in data.entries) {
        final key = entry.key;
        if (lang != 'en' && key.startsWith('@')) continue;
        if (lang == 'en' && !key.startsWith('@')) {
          final previous = owner[key];
          if (previous != null && previous != name) {
            stderr.writeln('duplicate key "$key" in areas $previous and $name');
            problems++;
          }
          owner[key] = name;
        }
        merged[key] = entry.value;
      }
    }
    final ordered = <String, Object?>{'@@locale': lang};
    final keys = merged.keys.where((k) => !k.startsWith('@')).toList()..sort();
    for (final k in keys) {
      ordered[k] = merged[k];
      if (merged.containsKey('@$k')) ordered['@$k'] = merged['@$k'];
    }
    final text = '${const JsonEncoder.withIndent('  ').convert(ordered)}\n';
    final out = File('lib/l10n/app_$lang.arb');
    if (check) {
      if (!out.existsSync() || out.readAsStringSync() != text) {
        stderr.writeln('${out.path} is out of date');
        stale = true;
      }
    } else {
      out.parent.createSync(recursive: true);
      out.writeAsStringSync(text);
    }
  }
  if (problems > 0) {
    stderr.writeln('$problems problem(s)');
    exit(1);
  }
  if (stale) {
    stderr.writeln('run: dart run tool/l10n/build_arb.dart');
    exit(1);
  }
  stdout.writeln(
    check ? 'ARB files are up to date' : 'wrote lib/l10n/app_*.arb',
  );
}

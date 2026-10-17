// Fails when screens bypass the design system (docs/polish/DESIGN_DECISIONS.md).
//
//   dart run tool/check_design_tokens.dart
//
// Rules, checked in lib/ outside the token files (lib/core/theme/):
//   raw-hex          Color(0x...)            -> AppColors
//   raw-colour       Colors.xyz (except Colors.transparent) -> AppColors
//   font-literal     fontFamily: 'Irina'     -> kAppFontFamily / AppTextStyles
//   raw-duration     Duration(milliseconds:) in an animation -> AppMotion
//   material-icon    Icons.xyz               -> AppIcons (custom artwork)
//   print            print(...)              -> AppLogger
// Exceptions live in tool/design_tokens_allowlist.txt, one per line:
//   <rule> <path> <match>   # reason
import 'dart:io';

class _Rule {
  const _Rule(this.id, this.pattern, {this.skip});

  final String id;
  final RegExp pattern;

  /// Matches that are fine (e.g. `Colors.transparent`).
  final bool Function(String match)? skip;
}

final _rules = [
  _Rule('raw-hex', RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)')),
  _Rule('raw-argb', RegExp(r'Color\.from(?:ARGB|RGBO)\(')),
  _Rule(
    'raw-colour',
    RegExp(r'(?<![A-Za-z])Colors\.[a-zA-Z0-9]+'),
    skip: (m) => m == 'Colors.transparent',
  ),
  _Rule('font-literal', RegExp(r'''fontFamily:\s*['"]''')),
  _Rule(
    'raw-duration',
    RegExp(r'(?:duration|Duration):\s*(?:const\s+)?Duration\(milliseconds:'),
  ),
  _Rule('material-icon', RegExp(r'(?<![A-Za-z])Icons\.[a-z_A-Z0-9]+')),
  _Rule('print', RegExp(r'(?<![A-Za-z_.])print\(')),
];

void main() {
  final allow = _readAllowlist();
  final used = <String>{};
  final violations = <String>[];

  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
  for (final file in files) {
    final path = file.path.replaceAll(r'\', '/');
    if (path.startsWith('lib/core/theme/') ||
        path == 'lib/firebase_options.dart') {
      continue;
    }
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.trimLeft().startsWith('//')) continue;
      for (final rule in _rules) {
        for (final m in rule.pattern.allMatches(line)) {
          final text = m.group(0)!;
          if (rule.skip?.call(text) ?? false) continue;
          final key = '${rule.id} $path ${_matchKey(rule.id, text)}';
          if (allow.contains(key)) {
            used.add(key);
            continue;
          }
          violations.add('$path:${i + 1}: [${rule.id}] $text');
        }
      }
    }
  }

  final stale = allow.difference(used);
  for (final s in stale) {
    violations.add('tool/design_tokens_allowlist.txt: stale entry "$s"');
  }

  if (violations.isEmpty) {
    stdout.writeln('Design tokens: no violations (${files.length} files).');
    return;
  }
  stderr.writeln('Design token violations (${violations.length}):');
  violations.forEach(stderr.writeln);
  exitCode = 1;
}

/// Material icons are allowed per icon name; other rules per file only.
String _matchKey(String rule, String text) =>
    rule == 'material-icon' ? text : '*';

Set<String> _readAllowlist() {
  final file = File('tool/design_tokens_allowlist.txt');
  if (!file.existsSync()) return {};
  return file
      .readAsLinesSync()
      .map((l) => l.split('#').first.trim())
      .where((l) => l.isNotEmpty)
      .map((l) => l.split(RegExp(r'\s+')).take(3).join(' '))
      .toSet();
}

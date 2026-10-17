// Every language has every message, with the same placeholders, and the ARB
// files match the fragments they are built from (tool/l10n/build_arb.dart).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _languages = ['en', 'ru', 'pl', 'de', 'es'];

Map<String, Object?> _arb(String lang) =>
    (jsonDecode(File('lib/l10n/app_$lang.arb').readAsStringSync()) as Map)
        .cast<String, Object?>();

/// Names in {name} and {name, plural, ...}. Plural and select branch bodies
/// (=0{...}, one{...}) follow a word character or '=', placeholders do not.
Set<String> _placeholders(String message) => RegExp(
  r'(?<![=\w])\{(\w+)[,}]',
).allMatches(message).map((m) => m.group(1)!).toSet();

void main() {
  final english = _arb('en');
  final keys = english.keys.where((k) => !k.startsWith('@')).toSet();

  test('the English template has descriptions for placeholders', () {
    for (final key in keys) {
      final placeholders = _placeholders(english[key]! as String);
      if (placeholders.isEmpty) continue;
      final meta = english['@$key'];
      expect(
        meta,
        isA<Map<String, dynamic>>(),
        reason: '"$key" needs @$key metadata',
      );
      final declared =
          ((meta! as Map<String, dynamic>)['placeholders']
                  as Map<String, dynamic>?)
              ?.keys
              .toSet();
      expect(declared, containsAll(placeholders), reason: key);
    }
  });

  for (final lang in _languages.skip(1)) {
    test('$lang has every message with the same placeholders', () {
      final other = _arb(lang);
      final missing = keys.where((k) => !other.containsKey(k)).toList()..sort();
      expect(missing, isEmpty, reason: '$lang is missing ${missing.length}');
      for (final key in keys) {
        expect(
          _placeholders(other[key]! as String),
          _placeholders(english[key]! as String),
          reason: '$lang "$key"',
        );
      }
      final extra = other.keys
          .where((k) => !k.startsWith('@') && !keys.contains(k))
          .toList();
      expect(extra, isEmpty, reason: '$lang has unknown keys');
    });
  }

  test('ARB files are built from the current fragments', () async {
    final result = await Process.run('dart', [
      'run',
      'tool/l10n/build_arb.dart',
      '--check',
    ], runInShell: true);
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  });
}

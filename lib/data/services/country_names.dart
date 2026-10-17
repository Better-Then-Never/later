import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/logging/app_logger.dart';

/// Country names in the app's language, from the platform (MainActivity.kt,
/// "later.app/locale": Android names every country in every language, so
/// the app ships no table). Elsewhere, or on failure, the code itself.
/// Cached per language.
class CountryNames {
  CountryNames({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('later.app/locale');

  final MethodChannel _channel;
  final Map<String, String> _cache = {};

  /// Names of [codes] ("PL") in [language] ("ru").
  Future<Map<String, String>> of(
    Iterable<String> codes,
    String language,
  ) async {
    final wanted = codes.toSet();
    final missing = [
      for (final c in wanted)
        if (!_cache.containsKey('$language:$c')) c,
    ];
    if (missing.isNotEmpty && !kIsWeb && Platform.isAndroid) {
      try {
        final names = await _channel.invokeMapMethod<String, String>(
          'countryNames',
          {'codes': missing, 'language': language},
        );
        names?.forEach((code, name) {
          if (name.trim().isNotEmpty) _cache['$language:$code'] = name;
        });
      } catch (e) {
        AppLogger.debug('Country names failed: $e');
      }
    }
    return {for (final c in wanted) c: _cache['$language:$c'] ?? c};
  }

  /// The flag emoji of [code] ("PL" → 🇵🇱): two regional indicator letters.
  static String flag(String code) => String.fromCharCodes(
    code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41),
  );
}

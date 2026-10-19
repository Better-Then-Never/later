// The MapLibre map's styles follow the app's colour tokens
// (tool/map/make_map_style.js, mission 2, §2.4).
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:later/core/theme/app_colors.dart';

Map<String, dynamic> _style(String name) =>
    jsonDecode(File('assets/map/style_$name.json').readAsStringSync())
        as Map<String, dynamic>;

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// [a] mixed into [b], [share] of [a] (as the generator mixes).
String _mix(Color a, Color b, double share) {
  int ch(Color c, int shift) => (c.toARGB32() >> shift) & 0xFF;
  String part(int shift) => (ch(a, shift) * share + ch(b, shift) * (1 - share))
      .round()
      .toRadixString(16)
      .padLeft(2, '0');
  return '#${part(16)}${part(8)}${part(0)}';
}

String? _paint(Map<String, dynamic> style, RegExp id, String key) {
  for (final layer in style['layers'] as List) {
    if (id.hasMatch(layer['id'] as String)) {
      return (layer['paint'] as Map?)?[key] as String?;
    }
  }
  return null;
}

void main() {
  for (final (name, ground, shares) in [
    ('light', AppColors.mapGroundLight, (park: 0.26, wood: 0.14, water: 0.18)),
    ('dark', AppColors.mapGroundDark, (park: 0.2, wood: 0.1, water: 0.14)),
  ]) {
    test('$name: ground, parks, woods and water come from the tokens', () {
      final style = _style(name);
      expect(
        _paint(style, RegExp(r'^background$'), 'background-color'),
        _hex(ground),
      );
      expect(
        _paint(style, RegExp(r'park'), 'fill-color'),
        _mix(AppColors.brandGreen, ground, shares.park),
      );
      expect(
        _paint(style, RegExp(r'^landcover_wood$'), 'fill-color'),
        _mix(AppColors.brandGreen, ground, shares.wood),
      );
      expect(
        _paint(style, RegExp(r'^water$'), 'fill-color'),
        _mix(AppColors.infoBlue, ground, shares.water),
      );
    });

    test('$name: OpenFreeMap tiles and fonts, no shaded-relief ocean', () {
      final style = _style(name);
      final sources = (style['sources'] as Map<String, dynamic>).values
          .cast<Map<String, dynamic>>();
      for (final s in sources) {
        final where = s['url'] ?? (s['tiles'] as List?)?.first;
        expect(where, startsWith('https://tiles.openfreemap.org/'));
      }
      expect(style['glyphs'], startsWith('https://tiles.openfreemap.org/'));
      // A raster layer (Natural Earth's relief) would paint the oceans.
      expect(
        (style['layers'] as List).where((l) => l['type'] == 'raster'),
        isEmpty,
      );
    });
  }
}

// The map's credits come from the style's sources (docs/map/ATTRIBUTION.md).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:later/features/map/map_credits.dart';

void main() {
  test('an attribution string becomes credits with their links', () {
    const html =
        '<a href="https://openfreemap.org" target="_blank">OpenFreeMap</a> '
        '<a href="https://www.openmaptiles.org/" target="_blank">&copy; '
        'OpenMapTiles</a> Data from <a href="https://www.openstreetmap.org/'
        'copyright" target="_blank">OpenStreetMap</a>';
    expect(MapCredits.parse(html), const [
      MapCredit('OpenFreeMap', 'https://openfreemap.org'),
      MapCredit('© OpenMapTiles', 'https://www.openmaptiles.org/'),
      MapCredit(
        'Data from OpenStreetMap',
        'https://www.openstreetmap.org/copyright',
      ),
    ]);
  });

  test('plain text and text after the last link are kept', () {
    expect(MapCredits.parse('© Example tiles'), const [
      MapCredit('© Example tiles'),
    ]);
    expect(MapCredits.parse('<a href="https://a.org">A</a> &amp; friends'), [
      const MapCredit('A', 'https://a.org'),
      const MapCredit('& friends'),
    ]);
  });

  test('credits of every source, in order, without repeats', () {
    final credits = MapCredits.fromStyle({
      'sources': {
        'one': {'attribution': '<a href="https://a.org">A</a>'},
        'two': {
          'attribution':
              '<a href="https://a.org">A</a> <a href="https://b.org">B</a>',
        },
        'three': {'type': 'geojson'},
      },
    });
    expect(credits, const [
      MapCredit('A', 'https://a.org'),
      MapCredit('B', 'https://b.org'),
    ]);
    expect(MapCredits.line(credits), 'A B');
  });

  test("the app's styles credit OpenStreetMap and OpenMapTiles, linked", () {
    for (final name in ['light', 'dark']) {
      final style =
          jsonDecode(File('assets/map/style_$name.json').readAsStringSync())
              as Map<String, dynamic>;
      final credits = MapCredits.fromStyle(style);
      expect(
        credits.where(
          (c) =>
              c.text.contains('OpenStreetMap') &&
              c.url == 'https://www.openstreetmap.org/copyright',
        ),
        hasLength(1),
        reason: name,
      );
      expect(
        credits.where((c) => c.text.contains('© OpenMapTiles')),
        hasLength(1),
        reason: name,
      );
      expect(MapCredits.line(credits), contains('OpenStreetMap'));
    }
  });
}

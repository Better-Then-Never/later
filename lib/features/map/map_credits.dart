import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/assets/app_assets.dart';

/// One credit of the map's data: what it says and where it links.
class MapCredit {
  const MapCredit(this.text, [this.url]);

  final String text;
  final String? url;

  @override
  bool operator ==(Object other) =>
      other is MapCredit && other.text == text && other.url == url;

  @override
  int get hashCode => Object.hash(text, url);

  @override
  String toString() => 'MapCredit($text, $url)';
}

/// The map's credits (docs/map/ATTRIBUTION.md), read from the style the map
/// draws: each source's `attribution` (written there from its provider's
/// TileJSON by tool/map/make_map_style.js), so they stay right when the
/// style or the tile provider changes.
abstract final class MapCredits {
  /// OpenStreetMap's page for reporting a mistake in the map.
  static const improveUrl = 'https://www.openstreetmap.org/fixthemap';

  /// The library that draws the map.
  static const rendererUrl = 'https://maplibre.org';

  /// The credits of a style (its JSON), in order, without repeats.
  static List<MapCredit> fromStyle(Map<String, dynamic> style) {
    final out = <MapCredit>[];
    final sources = style['sources'];
    if (sources is! Map) return out;
    for (final source in sources.values) {
      final html = source is Map ? source['attribution'] : null;
      if (html is! String) continue;
      for (final credit in parse(html)) {
        if (!out.contains(credit)) out.add(credit);
      }
    }
    return out;
  }

  /// The credits of the app's style (light and dark carry the same), read
  /// once.
  static Future<List<MapCredit>> load() async {
    final loaded = _loaded;
    if (loaded != null) return loaded;
    final style =
        jsonDecode(await rootBundle.loadString(AppMapStyles.light))
            as Map<String, dynamic>;
    return _loaded = fromStyle(style);
  }

  static List<MapCredit>? _loaded;

  /// The one line the map always shows: every credit, as the provider asks
  /// ("OpenFreeMap © OpenMapTiles Data from OpenStreetMap").
  static String line(List<MapCredit> credits) =>
      credits.map((c) => c.text).join(' ');

  static final _link = RegExp(
    r'''<a\b[^>]*?href\s*=\s*["']([^"']*)["'][^>]*>(.*?)</a>''',
    caseSensitive: false,
    dotAll: true,
  );
  static final _tag = RegExp(r'<[^>]+>');

  /// An attribution string (HTML, as TileJSON carries it) as credits: each
  /// link one credit; text before a link goes with it ("Data from" +
  /// "OpenStreetMap"); text after the last link is a credit of its own.
  static List<MapCredit> parse(String html) {
    final out = <MapCredit>[];
    var rest = 0;
    var pending = '';
    for (final m in _link.allMatches(html)) {
      pending = _clean('$pending ${html.substring(rest, m.start)}');
      final text = _clean('$pending ${m.group(2) ?? ''}');
      final url = _decode(m.group(1) ?? '').trim();
      if (text.isNotEmpty) out.add(MapCredit(text, url.isEmpty ? null : url));
      pending = '';
      rest = m.end;
    }
    final tail = _clean(html.substring(rest));
    if (tail.isNotEmpty) out.add(MapCredit(tail));
    return out;
  }

  static String _clean(String s) =>
      _decode(s.replaceAll(_tag, ' ')).replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _decode(String s) => s
      .replaceAll('&copy;', '©')
      .replaceAll('&#169;', '©')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');
}

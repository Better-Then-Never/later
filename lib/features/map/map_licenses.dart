import 'package:flutter/foundation.dart';

/// The map's notices for the app's open source licenses page
/// (docs/map/ATTRIBUTION.md). Flutter lists the Dart packages' licenses on
/// its own (maplibre_gl among them); not the native MapLibre library inside
/// the Android and iOS builds, the map data, the tile schema, the style or
/// its fonts and icons. Registered once at start.
abstract final class MapLicenses {
  static bool _registered = false;

  static void register() {
    if (_registered) return;
    _registered = true;
    LicenseRegistry.addLicense(() async* {
      for (final (packages, text) in entries) {
        yield LicenseEntryWithLineBreaks(packages, text);
      }
    });
  }

  /// (names as the licenses page lists them, text).
  static const entries = [
    (['MapLibre Native'], _mapLibreNative),
    (['OpenStreetMap data'], _openStreetMap),
    (['OpenMapTiles schema'], _openMapTiles),
    (['OpenFreeMap'], _openFreeMap),
    (['Map style (Positron, Dark Matter)'], _style),
    (['Noto Sans (map labels)'], _noto),
    (['Maki icons (map style)'], _maki),
  ];

  static const _mapLibreNative = '''BSD 2-Clause License

Copyright (c) 2021 MapLibre contributors

Copyright (c) 2018-2021 MapTiler.com

Copyright (c) 2014-2020 Mapbox

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.''';

  static const _openStreetMap =
      'Map data © OpenStreetMap contributors.\n\n'
      'The data is available under the Open Database License (ODbL) 1.0: '
      'https://www.openstreetmap.org/copyright';

  static const _openMapTiles =
      'The map tiles follow the OpenMapTiles schema, © OpenMapTiles '
      '(https://openmaptiles.org), licensed under Creative Commons '
      'Attribution 4.0 International (CC-BY 4.0).';

  static const _openFreeMap =
      'Map tiles, fonts and icons served by OpenFreeMap '
      '(https://openfreemap.org).';

  static const _style =
      "The map's style is OpenFreeMap's Positron and Dark styles (MIT, "
      'Copyright (c) 2023 Zsolt Ero), recoloured for Later. Positron is '
      'forked from OpenMapTiles positron-gl-style (code: BSD 3-Clause; '
      'design: CC-BY 4.0), derived from CartoDB Basemaps, designed by Stamen '
      'and Paul Norman for CartoDB Inc. (CC-BY 3.0).';

  static const _noto =
      'The map labels use Noto Sans, Copyright 2022 The Noto Project Authors '
      '(https://github.com/notofonts), licensed under the SIL Open Font '
      'License, Version 1.1: https://openfontlicense.org';

  static const _maki =
      'Icons in the map style come from the Maki icon set (CC0 1.0 '
      'Universal).';
}

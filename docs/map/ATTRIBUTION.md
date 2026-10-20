# ATTRIBUTION.md: the map's credits and licences

Not legal advice: what the providers' own pages say (read 19 Oct 2026), and what the app does about it.

## What the map uses
| Part | What | Licence / terms | What it asks for on the map |
|---|---|---|---|
| Map data | OpenStreetMap | ODbL 1.0 | "OpenStreetMap" credited, making clear the data is under the ODbL (e.g. "OpenStreetMap" linking to openstreetmap.org/copyright); visible without interaction, in a map corner or next to the map, or on a splash or pop-up at start; it may collapse (after 5 s, on interaction, or on dismiss) **if the licence information can still be found**, e.g. from an "(i)" button in the corner or an About entry ([OSMF attribution guidelines](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines)). |
| Vector tile schema | OpenMapTiles | CC-BY 4.0 (design) | "Products or services using maps derived from OpenMapTiles schema need to visibly credit OpenMapTiles.org", e.g. "© OpenMapTiles" linked to openmaptiles.org, in a map corner next to the OSM credit ([LICENSE.md](https://github.com/openmaptiles/openmaptiles/blob/master/LICENSE.md)). |
| Tiles, fonts, icons | OpenFreeMap (public instance) | free, commercial use allowed, no SLA ([openfreemap.org](https://openfreemap.org), [ToS](https://openfreemap.org/tos/)) | Its pages show "OpenFreeMap © OpenMapTiles Data from OpenStreetMap" (with links) as the attribution; MapLibre showed it from the tiles' TileJSON. The ToS add nothing about attribution (no logo). |
| Map style | OpenFreeMap's Positron and Dark styles, recoloured by `tool/map/make_map_style.js` | MIT (OpenFreeMap styles); Positron: BSD 3-Clause code, CC-BY 4.0 design, from CartoDB Basemaps (CC-BY 3.0) ([LICENSE.md](https://github.com/hyperknot/openfreemap-styles)) | Notice in the licences page. |
| Label font | Noto Sans | SIL OFL 1.1 | Notice in the licences page. |
| Style icons | Maki | CC0 1.0 | None required; listed anyway. |
| Renderer | MapLibre Native (Android, iOS) | BSD 2-Clause | No map credit; its licence text with the app (licences page). The Dart plugin `maplibre_gl` is listed by Flutter itself. |

## The strings and where they come from
`assets/map/style_*.json` → `sources.openmaptiles.attribution`, written there by `tool/map/make_map_style.js` from the
source's TileJSON (`https://tiles.openfreemap.org/planet`):

```html
<a href="https://openfreemap.org" target="_blank">OpenFreeMap</a> <a href="https://www.openmaptiles.org/"
target="_blank">&copy; OpenMapTiles</a> Data from <a href="https://www.openstreetmap.org/copyright"
target="_blank">OpenStreetMap</a>
```

`MapCredits` (`lib/features/map/map_credits.dart`) turns it into three credits: "OpenFreeMap" (openfreemap.org),
"© OpenMapTiles" (openmaptiles.org), "Data from OpenStreetMap" (openstreetmap.org/copyright). The style's unused
raster source (Natural Earth relief, no layer drew it) was dropped. A new provider: point the generator at its style,
run it, and the credits follow.

## What the app does now
- **MapLibre's own (i) button is off the map** (the plugin cannot switch it off; its margins put it off-screen).
- **On the map, top left right next to the filter button** (the owner's wish, 19 Oct): a small (i) disc in the style
  of the map's controls (surface, dark border, raised shadow, glyph painted like the zoom signs; 44 dp tap target;
  screen reader label "Map data and credits") and, next to it, the tiny credit line "OpenFreeMap © OpenMapTiles Data
  from OpenStreetMap" (10 sp, secondary text colour with a halo of the ground colour, up to three lines before the
  streak pill; it never catches a tap meant for the map). **The line shows at the start of each session and goes on
  the first touch of the map, at most after 5 s** (the owner asked to remove it; this is the OSMF allowance).
- **The (i) opens a sheet** (the shared edge sheet): the credits with their links, "Improve this map"
  (openstreetmap.org/fixthemap) and "Map rendered with MapLibre" (maplibre.org).
- **The capsule pin picker** (Create capsule > Move the pin, also MapLibre) has the same (i) bottom left and the same
  line (gone once the map is touched this session); MapLibre's own button is off its map too (20 Oct 2026).
- **Settings > About > "Map data and licenses"** opens the same sheet; **"Open-source licenses"** now also lists
  MapLibre Native (BSD 2-Clause text), OpenStreetMap data (ODbL), the OpenMapTiles schema (CC-BY 4.0), OpenFreeMap,
  the map style, Noto Sans (OFL 1.1) and Maki (`lib/features/map/map_licenses.dart`).
- Five languages (en, ru, pl, de, es); the credits themselves stay as the providers write them.

## The switch
`FeatureFlags.mapCreditCollapses` (`lib/core/config/feature_flags.dart`):
- `true` (**now, the owner's choice of 19 Oct 2026**): the line shows at the start of each app session until the map
  is first touched (at most 5 s), then only the (i) stays. OSMF allows collapsing on map interaction or after 5 s as
  long as the licence is findable from an (i) in the corner (it is). Risk: OpenMapTiles' CC-BY design licence asks
  to "visibly credit" in a map corner and says nothing about collapsing; whether an (i) alone is enough for them is
  not stated. To be sure, ask MapTiler (info@maptiler.com).
- `false`: the tiny line always shows next to the (i). Meets the OSMF and OpenMapTiles wording as plainly as
  possible.
- Removing the line altogether (the (i) only, from the start) is not offered: OSMF wants the credit visible without
  interaction at least at the start.

**Not done, by design**: hiding the credit everywhere except Settings (OSMF requires it visible on the map or at
start, and OpenMapTiles a visible credit).

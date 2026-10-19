# DECISION.md: which map engine

**Chosen: Option B, MapLibre**, with **OpenFreeMap**'s tiles: the owner's decision of 19 Oct 2026. MapLibre is the
default since then (`FeatureFlags.mapLibre`; a build goes back to Google Maps with `--dart-define=MAP_LIBRE=false`).

## How it was measured
`tool/dev/map_gesture.sh` on the Galaxy S20 FE (120 Hz), profile builds, the heavy seed (1,205 visible capsules),
the same two gestures for every engine (PERFORMANCE.md), played as **real touches** through Android's input system
(`tool/dev/touch/Pinch.java`): Flutter's synthetic test events reached Google Maps but MapLibre missed some, so
neither engine gets fake fingers. Recordings at about 120 frames a second are read frame by frame
(`map_gesture_report.py`).

## Numbers (per gesture; ranges over the runs)
| | A0: Google Maps today | A: Google, heat tiles ahead | **B: MapLibre** |
|---|---|---|---|
| Runs | 3 | 1 | 3 (+1 texture mode) |
| Heat layer changes | 3 (sweep), 9 (wave) | 3 / 9 | **0** |
| Heat tiles drawn by the app | 76 | 80 (from memory, 6 ms) | **0** (GPU layer) |
| Heat blinks, sweep | 10–16 | 13 | **0–1** |
| Bare frames (nothing at all), sweep / wave | 170–266 / 26–52 | — | **51 / 259**: the 0.3 s symbol crossfade at a bubble split, pins half-transparent but visible (frames checked by eye); no frame without either layer |
| Markers added / removed on the map | 490–661 / 623–794 (sweep), 1,432–1,572 / 1,397–1,519 (wave) | same | **0**: MapLibre groups and draws them itself |
| Recording gaps ≥ 100 ms | 1–3 (longest 316 ms) | 2 (334 ms) | **0** |
| Frozen map ≥ 150 ms | 1–7 | 2 | **0** |
| Answer to a finger (first camera move) | 40–86 ms | — | **30–53 ms** |
| Flutter frames janky (8.3 ms) | 0–1.5 % | 0 % | 3.3–6.4 % with the default SurfaceView; **0 %** (worst 5.3–6.6 ms) in texture mode (`useHybridComposition`), kept |

Two traps found on the way, both fixed in the spike: MapLibre's default `maplibre_minimum_scale_speed` ignored a
slowly closing pinch for 0.7 s (overridden in `android/app/src/main/res/values/maplibre_gestures.xml`: 40–66 ms
now, Google answers in about 95), and its default SurfaceView made Flutter fall back to hybrid composition (raster
4.6 ms a frame on average instead of 1.6).

## Why not A
Google Maps cannot meet the core criteria however its layers are fed:
- A tile layer (our heat, and the plugin's own heatmap, which draws nothing on this phone at all) is kept per
  whole zoom level and shown **blank** at every level change until the new level's tiles arrive. Drawing every tile
  ahead and serving it from memory (Spike A: 6 ms a tile instead of 26) left the blinks unchanged.
- A native marker cannot fade, grow or move: any change re-sends all its options and Android re-creates its bitmap
  (blank for a frame or more). Clusters can only be swapped, never split or merged; animating them means drawing
  copies in Flutter, which trail a moving map (M-02, M-04).
- Grouping and adding markers is Flutter's job and Android's main thread's (where Flutter's vsync comes from): a
  zoom level changes hundreds of markers.

## Why B
The heat, bubbles and pins are layers of the map, drawn on the GPU: their look is a function of the zoom that the
map evaluates every frame (`MapZoomVisuals`: the heat fades out between zoom 11.6 and 12.3 while the markers fade
in between 11.0 and 11.6, so they are whole before the heat starts to go), the capsules are grouped by the map itself (`cluster: true`), and Flutter sends nothing
during a gesture. Bubbles split and merge with a crossfade, at every zoom, under the fingers.

## Package
`maplibre_gl` 0.27.1 (pub.dev, published Sep 2026; previous releases monthly since April; BSD-3-Clause; Flutter
≥ 3.29, Dart ≥ 3.7; this project: 3.38.4 / 3.10.3). Android and iOS (iOS not run here: the project has no iOS rig).
`maplibre` 0.3.x (the newer API) needs Flutter 3.44: not usable yet.

## Tiles: decided, OpenFreeMap (19 Oct 2026)
Free options as checked on 19 Oct 2026 (their own pages; terms change, so check again before relying on a limit):
| Option | Free for a commercial app? | Limits | Key | Notes |
|---|---|---|---|---|
| **OpenFreeMap** (chosen) | yes | none on views or requests | none | donations; no SLA; attribution "OpenFreeMap © OpenMapTiles Data from OpenStreetMap", shown by MapLibre's "i" button from the tile description (checked on the phone) |
| VersaTiles (tiles.versatiles.org) | yes | none stated | none | OSM attribution only; no 24/7 guarantee yet |
| Protomaps, self-hosted | yes (only hosting and traffic cost) | our own | none | one PMTiles file on our own storage/CDN; most control, most setup |
| Protomaps hosted API | no (non-commercial; commercial = GitHub sponsor) | soft 1M tile requests/month | yes | |
| MapTiler Cloud | no (free plan non-commercial); paid from about $25/month | about 5k sessions, 100k requests/month | yes | satellite and hybrid styles |
| Stadia Maps | no (free plan non-commercial; any for-profit company counts as commercial); paid from about $20/month | about 200k credits/month | yes | |

What changes against Google: no Google place labels and POIs (OSM's instead), **no satellite or hybrid** with
OpenFreeMap (the map-look setting would have to fall back or a provider with imagery chosen), OSM attribution must
stay visible (the "i" button, like the Google logo today). Our look is kept: `tool/map/make_map_style.js` recolours
OpenFreeMap's Positron and Dark styles with the app's map palette (`assets/map/style_*.json`).

**Decision**: OpenFreeMap (no key, no cost, commercial use allowed). If it ever goes down for long or a service
level is needed, the same styles work with a self-hosted Protomaps/OpenMapTiles file or a paid MapTiler plan (the
source URLs in `tool/map/make_map_style.js`).

## Risks
- A second map SDK in the app: MapLibre's native library is 10.3 MB for arm64 (about 3.6 MB compressed in a
  download) plus its Java classes. The capsule creation pin picker is on MapLibre too (19 Oct); Google Maps stays
  in the app only for `MAP_LIBRE=false`.
- iOS untested.
- OpenFreeMap availability (no SLA).

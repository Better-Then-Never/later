# BLOCKERS.md: what is not done or not verified (map engine)

## Owner decisions
- Decided 19 Oct 2026: OpenFreeMap tiles, and MapLibre on by default (`FeatureFlags.mapLibre`).
- Decided 19 Oct 2026: **the satellite / hybrid map look is hidden** while MapLibre is on (OpenFreeMap has no
  imagery). Settings shows no map-look choice; a choice saved earlier is kept, so it returns with
  `MAP_LIBRE=false`. If satellite is wanted back: MapTiler has satellite
  and hybrid styles (paid for commercial use); Esri World Imagery needs an ArcGIS account and its terms; Sentinel-2
  cloudless is non-commercial only and too coarse for streets.
- **Open: production reliability of OpenFreeMap** (mission 2 brief, §2.4): free, no key, commercial use allowed,
  no limits stated, but no SLA and run on donations; tiles answered in 60–150 ms from here. If it is down the map
  shows the cached tiles and the capsules, no streets for unseen areas. Fallbacks, all with the same style files:
  VersaTiles (free, no SLA), self-hosted Protomaps/OpenMapTiles (only hosting cost), MapTiler (paid).

## Not built
- **The first open's pop-in in rings** (M-03 on the Google map): on MapLibre the pins of the first screen appear at
  once when the capsules are read. The split and merge on zooming is built (mission 2).
- **Tile prefetch**: nothing is downloaded ahead; MapLibre caches what it drew. Zooming into an area never seen
  shows the coarser level scaled up until its tiles arrive (60–150 ms each here).
- **Pan bounds**: none (MapLimits explains why the plugin's bounds held the camera on the date line); the zoom
  limit (3) already keeps a whole-world ocean off the screen.

## Not verified
- **iOS**: nothing run (no iOS rig in this project). Read only: the iOS deployment target (13.0) matches the
  MapLibre pod's minimum (6.28.0: iOS 13), and styles from the app's assets are supported. The gesture-speed
  override is an Android resource; iOS may need its own check. The split and merge only uses GeoJSON sources and
  symbol layers, which MapLibre has on iOS.
- **The two stalls of the owner's recording at 0:59 and 1:26** (235, 202, 170 ms): most likely the instant tap
  zooms (DIAGNOSIS.md §9) and the Google page's clustering on every camera stop, both gone; not provable from the
  video alone, and not seen again in any harness run.
- **One tap-zoom step of 0.31 of a level** (`after_r1`, the + button, in the first seconds after the app started);
  the next two runs and two more with 2,205 capsules had none (largest 0.18). Cause not found; the flow warms the
  map up with a double tap and a two-finger tap first, the button came after them.
- **Re-checked on MapLibre this mission**: pin tap and card, selected pin raised with its shadow (M-02), bubble
  tap, light and dark styles, zoom limits, cold start, 2,205 capsules. **Not re-checked this mission** (unchanged
  code, checked in mission 1): filters, Russian at 130 % text, first-capsule hint, offline start.

## Verified (mission 1, 18 Oct 2026, Galaxy S20 FE)
- **Offline** (Wi-Fi off; the emulators still answer over USB, so only the tiles are offline): a cold start shows
  the streets at the saved place from MapLibre's tile cache; panning to a place seen less shows the coarser
  cached tiles scaled up, never a blank map; the detail returns once online.
- **Russian at 130 % text**: the capsule card, the buttons, the attribution mark and the filter sheet fit.
- **APK size**: MapLibre's native library is 10.3 MB for arm64 (about 3.6 MB compressed in a download).
- **The "almost ready" screen after the map (M-07)**: fixed in `8426062` (found by reading, covered by tests).

## Known limits
- Two capsules at the very same coordinates show as one pin at the closest zoom (one under the other), as on the
  Google map; a bubble of them, tapped, zooms to where it splits (never, at the last level).
- The split and merge moves at most 60 pieces, those on screen, nearest the middle first; beyond that the rest
  changes at once.
- Under a fast pinch's first movement the map's zoom lags the fingers by up to 0.43 of a level for a moment
  (MapLibre's gesture threshold, `maplibre_gestures.xml`); on average it follows within 0.02 of a level.
- The gesture report's "dropout frames" now count the deliberate heat-to-bubbles handover (a sharp drop of heat
  while markers grow in); they no longer indicate a fault (PERFORMANCE.md, After 2).
- An Android animator scale of 0 (the system's "remove animations") makes MapLibre's own double tap, two-finger
  tap and zoom coast jump, as in any Android app; the app's buttons and moves follow its own reduce-motion setting.
  `tool/dev/map_gesture.sh` refuses to measure at another scale than 1.0.
- The profile build warns that `maplibre_gl`, `integration_test` and `jni` ask for Android NDK 28.2 while the
  project sets 27.0; the builds succeed and run.

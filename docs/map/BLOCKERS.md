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

- Decided 19 Oct 2026: the map credit line goes away (the owner): it shows at the start of each session until the
  map is first touched (at most 5 s), then only the (i), now top left next to the filter
  (`FeatureFlags.mapCreditCollapses = true`). OSMF allows it; OpenMapTiles' licence asks for a visible credit and
  says nothing about collapsing: ask MapTiler to be sure (docs/map/ATTRIBUTION.md).

## Open after mission 4 (the full map at once, docs/map/COLD_START.md)
- **Owner: delta sync's backend is not deployed** (function `recordCapsuleDeletion`, `capsule_deletions` rules, four
  indexes, the TTL policy); `FeatureFlags.mapDeltaSync` is off, so the app still reads every friends' and public
  capsule at each start (as before). Deploy steps in COLD_START.md. The four indexes are only checked by reasoning:
  the emulator does not enforce indexes; a wrong one makes its query fail, and the map then reads everything (tested).
  Deletions made before the deploy have no record (see COLD_START.md for a safe order).
- **Owner: OpenFreeMap's terms** (updated 14 Oct 2026) forbid collecting tiles "in automated ways" except offline
  downloads the user asks for (at most 3,000 tiles or 50 MB, 4 parallel requests, a User-Agent naming the app). No
  prefetch was built. ATTRIBUTION.md's "commercial use allowed" came from their front page; the current terms page
  does not say it either way: worth reading again before relying on it.
- **A tap in the merge window** (the 1 to 1.5 s after the reveal, before a source answers) opens the card when the
  phone's Firestore copy answers, 0.85 s in the measured case, busy with the start's queries; the pin rises then
  too. Later taps are instant. Fix if wanted: raise the pin and show a shaped card skeleton at once.
- **Offline, the pins can come 0.25 s before the streets** (the cover's 1.8 s limit passes first: MapLibre's style
  takes 2.7 s offline while it fails to check its description again).
- **Firestore's first answer is still 1.2 s or more after the map asks** (the SDK's local queue at a start). Not
  seen any more (the store), but it sets when "fresh" data arrive and the merge-window tap above.
- **The first frames rasterize in 30 to 100 ms** (Impeller's first frames and MapLibre's start, under the splash or
  the cover): not seen as motion, but they delay the start by a few frames.
- **The launch screen from `am start` (the rig) shows no logo** on this Samsung (Android 13), though
  `windowSplashScreenBehavior=icon_preferred` is set; from the home screen it shows the logo. Only the rig's video
  differs.
- **iOS not run**: the launch colour is a named colour (`LaunchBackground`, light and dark) referenced from the
  storyboard, written by hand without Xcode.
- **Not measured on the phone**: 4,000 capsules (2,205 were; 5,000 stored pins decode in milliseconds in a test), a
  throttled network, account switch and sign-out on the phone (unit tests only: they would sign the test account
  out), Russian and large text (no text in the sequence).
- **Torn frames vary a lot between runs** (4 to 29 per flow; the mission 3 code 4 to 6 the same evening); the
  select flow's camera now centres on the tapped capsule, which sends the picture again as it moves.
- **Rig:** a functions test run left its Firestore emulator on port 8280 (process 27312); stopping it was not
  allowed here. The next `npm run test:emulate` in functions/ needs that port.

## Open after mission 3 (flashing bubbles, docs/map/FLASH_FIX.md)
- **One glitch in one of three fast runs**: a "7" bubble opened and closed again within about 30 ms at the first
  fast flick out of the heat (`final_r1`, 2.3 s). Not reproduced in a traced run (the shown level only stepped
  forward). Suspected: MapLibre re-cutting the source's tiles as the flick crosses a whole zoom level. Not proven.
- **Dark mode**: one probe run (`final_dark`) counted 2 / 4 / 5 frames with a level-12 bubble missing for a frame
  (slow / normal / fast), all in frames where the map showed two consecutive pictures, and far fewer probes than in
  light (184 and 24 instead of about 1,500; why is not known). Light on the same code: 0.
  Not repeated; needs a second dark run before calling it either way.
- **Torn frames**: 1–3 frames per 20 s flow where tiles show two consecutive pictures (MapLibre parses each tile of
  a source on its own worker). One frame each (8 ms); not seen by eye.
- **Reduced motion not measured on the phone**: the system's "remove animations" sets Android's animator scale to
  0, which the gesture harness refuses (it breaks MapLibre's own tap zooms). By the code: no flights (pieces switch
  at once), the selected pin rises and lands without motion.
- The video detector cannot tell a real fast change (a zoom fade completing in one camera jump, a bubble opening)
  from a flash: its flags were looked at frame by frame (FLASH_FIX.md "Final").
- **"About me"**: Settings' About page is named "About me" ("О себе", "Über mich", "O mnie", "Sobre mí") in every
  language though it is the app's About page. Found in mission 3; not changed (outside it).

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

# BLOCKERS.md: what is not done or not verified (map engine)

## Owner decisions
- **Tile source** for MapLibre (DECISION.md): OpenFreeMap is used for development (no key, no cost, no SLA).
  Until decided, `FeatureFlags.mapLibre` stays off and the Google map is what users get.
- **Turning the flag on** (`lib/core/config/feature_flags.dart`, today only `--dart-define=MAP_LIBRE=true`).
- **Satellite / hybrid map look** (the map-look setting, used by the map page, the pin picker and the device
  settings page): OpenFreeMap has no imagery, so on MapLibre the setting has no effect. Sources looked at: MapTiler
  (satellite and hybrid styles; a key, a free tier, then paid plans), Esri World Imagery (ArcGIS terms and
  attribution, an account for production use), Sentinel-2 cloudless (free only for non-commercial use, and 10 m
  pixels are too coarse for streets). Either a provider is chosen or the setting is hidden while MapLibre is on.

## Not built on the MapLibre map
- **Flying capsules on the first open and on the zoom buttons** (M-03/M-04's sprites): MapLibre's own symbol fade
  (0.3 s) replaces them; capsules fade in as their tiles arrive, bubbles crossfade when they split or merge.
- **The capsule creation pin picker** still uses Google Maps (its own small map; not part of this mission).

## Not measured
- **The final "After" numbers under the fingers** (PERFORMANCE.md): `MAP_LIBRE=1 tool/dev/map_gesture.sh after 3`
  was stopped twice because the computer ran low on memory during the profile build, and was not restarted
  without the owner. The latest MapLibre numbers under the fingers are the spike's (DECISION.md, 3 runs + 1, same
  harness and gestures), from before the page reached parity.
- **2,000+ capsules**: runs together with the measurement above (1,000 extra friends' capsules added on the local
  emulator only, removed afterwards). The seed's account sees 1,205; the MapLibre sources take all visible
  capsules (no viewport bound: clustering runs in the map's worker).
- **iOS**: nothing run (no iOS rig in this project). Read only: the iOS deployment target (13.0) matches the
  MapLibre pod's minimum (6.28.0: iOS 13), and styles from the app's assets are supported. The gesture-speed
  override is an Android resource; iOS may need its own check.

## Verified (18 Oct 2026, Galaxy S20 FE)
- **Cold start** (profile build, MapLibre on; PERFORMANCE.md "After"): no white frame; streets at the saved place
  1.4 to 1.8 s after the tap (Google: about 4.5 s). The pins appear about 0.5 s after the capsule data arrives;
  before `5a340d0` they waited for the next data change (capsules that arrived while the style loaded were
  dropped).
- **Offline** (Wi-Fi off; the emulators still answer over USB, so only the tiles are offline): a cold start shows
  the streets at the saved place from MapLibre's tile cache; panning to a place seen less shows the coarser
  cached tiles scaled up, never a blank map; the detail returns once online.
- **Russian at 130 % text**: the capsule card (title, date, "Посмотрите, что внутри!", "Открыть"), the buttons, the
  attribution mark and the filter sheet fit; the buttons move up with the card.
- **APK size**: MapLibre's native library is 10.3 MB for arm64 (uncompressed in the APK, about 3.6 MB compressed in
  a download) plus its Java classes (not measured separately). A store download carries one ABI; the universal APK
  carries all four.
- **The "almost ready" screen after the map (M-07)**: found by reading, not reproduced on the phone (the seed
  account is complete). A first Google sign-in is signed in before its profile is created; the home screen showed,
  then "Almost there" over it after the 3 s grace. Fixed in `8426062`: the launch picture stays until it is known
  whether the profile exists (or its stream fails); covered in `test/app/session_and_auth_test.dart`.
- **Bubble tap** (`1f47e6e`): the camera fits the bubble's own capsules (`getClusterLeaves`), as the Google map
  does; when they all stand in one spot it moves in to where the bubble splits.

## Known limits
- Two capsules at the very same coordinates show as one pin at the closest zoom (one under the other), as on the
  Google map.
- MapLibre's symbol crossfade (fixed at 0.3 s on Android, no setting) makes a splitting bubble and its new pins
  half-transparent for a moment; never a frame without either.
- The profile build warns that `maplibre_gl`, `integration_test` and `jni` ask for Android NDK 28.2 while the
  project sets 27.0; the builds succeed and run.
- The harness records about 120 frames a second with `screenrecord`; the recorder itself can drop frames, so a
  single gap of ≥100 ms in a recording is checked against MapStats' own frame gaps before it is called a stall.

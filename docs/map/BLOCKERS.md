# BLOCKERS.md: what is not done or not verified (map engine)

## Owner decisions
- **Tile source** for MapLibre (DECISION.md): OpenFreeMap is used for development (no key, no cost, no SLA).
  Until decided, `FeatureFlags.mapLibre` stays off and the Google map is what users get.
- **Turning the flag on** (`lib/core/config/feature_flags.dart`, today only `--dart-define=MAP_LIBRE=true`).

## Not built on the MapLibre map
- **Satellite / hybrid map look** (the map-look setting): OpenFreeMap has no imagery; on MapLibre the setting has
  no effect. Needs a provider with imagery (MapTiler) or the setting hidden when MapLibre is on.
- **Flying capsules on the first open and on the zoom buttons** (M-03/M-04's sprites): MapLibre's own symbol fade
  (0.3 s) replaces them; capsules fade in as their tiles arrive, bubbles crossfade when they split or merge.
- **The capsule creation pin picker** still uses Google Maps (its own small map; not part of this mission).
- **Bubble tap** zooms two levels in around the bubble (the plugin has no "cluster expansion zoom"); the Google
  map fits the bubble's capsules.

## Not verified
- **iOS**: nothing run (no iOS rig in this project). `maplibre_gl` supports iOS; the styles, layers and gesture
  thresholds may need iOS checks.
- **Offline**: MapLibre caches tiles it has drawn, but a cold start without network shows only the ground colour
  and the capsules (no streets) until tiles load. Not measured.
- **Russian at 130 % text** on the MapLibre page: the card, hint and buttons are the Google page's own widgets
  (verified there before), not re-checked on MapLibre.
- **2,000 capsules**: the seed's account sees 1,205; the MapLibre sources take all visible capsules (no viewport
  bound needed: clustering runs in the map's worker). 2,000+ not measured.
- **APK size** with the second map SDK: not measured.
- **The "almost ready" screen after the map (M-07)**: not reproduced in this mission (the seed account is complete).

## Known limits
- MapLibre's symbol crossfade (fixed at 0.3 s on Android, no setting) makes a splitting bubble and its new pins
  half-transparent for a moment; never a frame without either.
- The harness records about 120 frames a second with `screenrecord`; the recorder itself can drop frames, so a
  single gap of ≥100 ms in a recording is checked against MapStats' own frame gaps before it is called a stall.

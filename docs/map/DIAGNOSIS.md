# DIAGNOSIS.md: why the map blinks, goes bare and pops

From the baseline (PERFORMANCE.md), the recordings, `MapStats`, and the plugin's source
(`google_maps_flutter_android` 2.19.10, `Convert.java`, `MarkersController.java`, `TileOverlaysController.java`).
Each cause names its owner's defect (mission §1).

## 1. The heat blinks off and on while pinching (§1.1): it is redrawn per zoom level, tile by tile
- The heat (M-11) is a `TileOverlay` whose tiles the app draws (`CapsuleHeatmap.getTile`, an isolate per tile).
  Google Maps keeps a tile layer's tiles **per integer zoom level**: when the zoom crosses a whole number it asks
  for the new level's tiles and shows **nothing** where they have not arrived yet (no scaled copy of the previous
  level, unlike the base map). With `fadeIn: false` each arrives as a hard pop.
- A tile takes 26 ms on average to come back (isolate start, drawing, PNG, the plugin's blocking channel call);
  a screen needs 6 to 15, asked a few at a time: the heat is gone or half drawn for 100–300 ms after every level
  (recording: owner4 9.94–10.21 s fully gone, 10.41 s half drawn; sweep: 12 blinks per run).
- The native heatmap (`Heatmap`, the plugin's own) cannot replace it: it is the same mechanism (a
  `HeatmapTileProvider` tile overlay) and on this phone it draws nothing at all (M-11, LOG.md).
- **Not** caused by rebuilding the layer: heat mutations are 3 (sweep) and 9 (wave) per run, all the visibility
  switch of cause 2; the overlay object itself is stable.

## 2. Frames with neither heat nor markers (§1.2): a hard switch at zoom 12 with nothing to cover it
- Below zoom 12 the heat shows, above it the markers: `visible: !map.showMarkers` flips in the frame the zoom
  crosses 12 (`MapController._setZoom` notifies), so the heat disappears at once.
- The markers for the new view are grouped on that level crossing (live under a finger since M-11) and sent to
  the map **12 per frame** (to keep Android's main thread free), so the first bubbles appear 1–2 frames later and
  the last about 10 frames later. Meanwhile the map is bare: 80–350 ms, 173–361 dropout frames per run.
- There is no crossfade, and on Google Maps there cannot be one (cause 3): neither the heat layer's
  `transparency` nor a marker's `alpha` can be changed per frame without a redraw.

## 3. Bubbles and pins pop (§1.3): every level replaces the whole set, and native markers cannot fade
- Bubbles are grouped on a grid at `floor(zoom)`: crossing a level changes almost every group, so almost every
  marker is removed and a new one added. The wave adds and removes about 1,600 markers each (largest single
  update 121). Bubble ids no longer change between levels when the members are the same (M-04), but at a new
  level the members differ.
- A native marker cannot be animated: the plugin sends **all** of a marker's options on any change and Android
  re-creates its bitmap (`Convert.interpretMarkerOptions` → `setIcon`), so a marker whose alpha or scale changes
  is missing for a frame or more (seen in M-02). Fading, growing, splitting and merging can only be done by
  drawing copies in Flutter over the map (M-03/M-04's sprites); those trail a moving map, because the map reports
  its camera after it has drawn, in bursts (M-02: 5–40 ms apart), so under a finger the markers simply swap.
- Adding markers runs on Android's main thread, where Flutter's vsync also comes from: about 100 at once held the
  frames for 20–40 ms (M-11); spreading them over frames avoids the stall but makes the arrival visible.

## 4. The cluster layer is noisy (§1.4)
- A 64 px grid at `floor(zoom)`, at most 150 markers: at city zoom that is many bubbles of 2–4 next to single pins,
  and a bubble's position is its members' mean, so it can sit next to or under a pin of a neighbouring cell. The
  number is 15 px bold on a 34–46 dp disc. Bubble size grows only with the digit count, not the count itself.

## 5. Stalls (§1.5)
- The 21 gaps (longest 299 ms) of the owner's recording come from the **debug build** run by `tool/dev/run.sh`
  (JIT, assertions): the same gestures in profile mode have 0–2 gaps of 100 ms or more per 30 s gesture (longest
  117–332 ms) and the map changes in about 114 recorded frames a second.
- The remaining profile stalls fall where the marker set is replaced (a level crossing with 100+ markers) and
  where the camera crosses into the street levels while the base map loads its tiles.

## 6. Building and style flicker at street level (§1.6)
- No style call during gestures (style changes: 0 in every run) and no map widget re-creation: the grey building
  footprints are the base map's own street-level tiles (zoom 16+) drawn while their level loads; they come and go
  as the zoom crosses whole levels, like the heat tiles but in Google's renderer.

## 7. The heatmap's colours (§1.8)
- The build the owner ran is `e12f7e8` (M-11): the heat is the new blue → green → yellow → orange ramp, made at the
  owner's request on 18 Oct after the single brand-green native heatmap (D-19) turned out to draw nothing on the
  phone. D-19 is out of date; the ramp is the current, owner-approved look ("the colours are okay").

## 8. Cold start (§2C, M-06)
- Six stages (PERFORMANCE.md): the system window is white, the map page waits for `MapController.start` (icons,
  location) before it builds the map, the native map view takes about a second to inflate and shows its beige
  "no tiles" background, the user's figure and pins arrive before the streets.

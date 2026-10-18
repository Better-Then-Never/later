# LOG.md: interactive polish session, one entry per finished item

Branch `polish/interactive-fixes`. Newest last. Each entry: date, item, what changed, commit, how verified.

## 2026-10-18, M-01 Map control sizes (`8eaa583`)
- **Was**: every map control was 52 dp (zoom pill halves, compass, my location, filter, the streak pill), heavy next
  to the markers.
- **Changed**: one token `AppSizes.mapControl` = 44 dp (the tap-target minimum) and `AppSizes.mapControlGap` = 10
  in `lib/core/theme/app_dimens.dart`, used by all five; insides scaled in proportion (icon padding 13 → 11 and
  10 → 8, filter dot 14 → 12, zoom signs and the compass needle drawn relative to the button, streak flame 20 → 17
  and number 18 → 16); the stacked positions use the gap token.
- **Verified**: phone (S20, debug): all five 132 px = 44 dp in the accessibility tree; light; dark + text 1.3
  (pill widens, stays 44 tall; compass needle scaled); controls lift above an open capsule card; tap audit: only
  markers cut off by the screen edge (known exception). Tests: map, compass (now checks the token and ≥ 44),
  moments, clusters, tap targets. No visible text changed, so no language check was needed.

## 2026-10-18, M-02 Selected capsule emphasis (`0d1c9be`)
- **Was**: a tapped capsule looked like every other pin; only the card at the bottom said which one was chosen.
- **Changed**: the selected pin pops (1.10 → 1.24 → 1.34 → settles at 1.28×) with a brand-green ring that fades in,
  and sits above the other pins and clusters (`lib/features/map/selected_pin.dart`). The four frames per pin colour
  are drawn once in the background after the pins load (`MarkerIcons.selectedFrames`); selecting steps through them
  every 60 ms (240 ms in all, within `AppMotion.reveal`), reduced motion shows the last frame at once. Only the one
  marker changes, so only it goes to the native map (no mass marker update, which is what froze the map before).
- **Verified**: phone (debug): selected pin grown and ringed with the card open; another pin takes the emphasis;
  deselecting brings it back. Profile build, 1 run: map_focus 1.3 % janky, worst 9.9 ms (1.8 % / 11.1 ms in the
  Session A final run); capsule_dialog 1.3 % (2 of 152 frames), worst 12.3 ms; map pan and zoom 0 %. Tests:
  `selected_pin_test.dart` (budget, only that marker changes, frames drawn for every colour). The pop itself is too
  quick to judge from stills.

## 2026-10-18, M-02 follow-up: jump, sway and hover instead of a ring (`f58508a`)
- **Owner**: the green outline clashed with the other pin colours; asked for motion instead (sway, hover, jump).
- **Changed**: no ring. The selected pin jumps off its spot (tip 13 dp up), lands, sways once (7°, −5°, 0° around
  its spot, through the marker's rotation, no new bitmaps) and rests hovering 9 dp above a soft blurred shadow
  that marks the spot, grown to 1.14×, on top of the other pins. Six marker updates in about 330 ms, then it is
  still (no continuous updates). Reduced motion: hovering at once.
- **Verified**: phone (debug): hovering with its shadow while the card is open. Tests updated (jump then land,
  rests upright, within `AppMotion.reveal`, anchored at its spot). Not re-measured in profile: same mechanism as
  the first version (6 marker updates instead of 4).

## 2026-10-18, M-02 follow-up 2: no flicker, a smooth sway, a gentle hover (`270c289`)
- **Owner**: the sway was too shaky; after it the pin should hover up and down a little. Then: the selected pin
  blinked (gone for a moment) while it moved.
- **Cause of the blink**: every change to a native marker re-sends all its options, and the Android plugin
  re-creates its bitmap each time (`setIcon` in `MarkersController.changeMarker`); a marker moved step by step
  blinked at every step. No native marker can be animated without it.
- **Changed**: the selected pin is drawn by Flutter over the map (`SelectedPinOverlay`); its native marker only
  turns invisible (one update when selected, one when it is back). The overlay starts and ends exactly as the
  native pin looks (48 dp, standing on its spot), so the swaps do not show. It grows to 1.14× as it jumps
  (14 dp up), lands at 9 dp, sways 5° with a fading swing (one frame never turns it more than 0.7°), then hovers
  ±2.5 dp every 1.6 s above a soft shadow; deselected, it lands back in 180 ms. Jump, sway and landing run every
  frame; the slow hover takes a step every 33 ms (about a physical pixel; a quarter of the frames).
  Reduced motion: hovering at once, landing at once.
- **Placing it**: `MapProjection` (Web Mercator in Dart, bearing, the map's padding) puts the spot on screen from
  each camera the map reports. Android keeps the map still when its padding changes (the card opening or
  closing) and moves the reported target instead, telling only with the next camera move. So `MapViewport`
  reads each camera with the padding in force when the map reported it (a padding counts from the first camera
  after the map confirmed it; one in between is told by not jumping). Tilt gestures are off (the maths assume a
  flat map; the compass already turned the map flat).
- **Verified**: phone (debug): the projection against the map's own `getScreenCoordinate` stays within 0.2 dp
  with the card opening, after closing it (no camera move), after a pan and on a reselect; a half-transparent
  native pin under a still overlay showed no double, also mid-pan; hovering with its shadow in light and dark;
  reduced motion hovering at once. Profile, 1 run each: map_focus 0.3 % janky (worst 8.4 ms) before the hover
  step, 0.4 % (one 25 ms raster frame of 254) after; capsule_dialog only its first frame over budget (18 ms, as
  before); map pan and zoom 0 %; fewer frames in all. Tests: `selected_pin_test.dart` (timing, starts and lands
  as the native pin, follows the map, the hover steps, reduced motion), `map_projection_test.dart`,
  `map_viewport_test.dart`. Gates green except the known flaky `capsule_creation_test.dart:151` (passes alone).

## 2026-10-18, M-02 follow-up 3: the selected pin stays on its spot while the map moves (`d7a849c`)
- **Owner**: with a capsule selected, moving the map made the pin wander around instead of staying in place.
- **Cause**: the map reports its camera only after it has drawn the frame, and in bursts (5 to 40 ms apart on a
  120 Hz screen), so a pin drawn by Flutter always trails a moving map and wobbles. Only a pin the map draws
  itself stays glued to it.
- **Changed**: while the map moves (a finger on it, or any camera animation: a tapped pin being centred, the
  zoom, location and compass buttons, a cluster), the map draws the floating pins, held in the exact pose the
  overlay left them in: the grown pin lifted by its anchor, leaned by its rotation, over a still shadow (two
  bitmaps per run, drawn in the background as in the first version). When the map is still again the Flutter
  pin comes back in the same pose and goes on. Every hand-over waits until the other side has been drawn
  (`_afterNativeMap`), and starts while the map is still (a finger touching, or before a camera animation is
  asked for), so the pin is never missing, doubled or trailing. A tapped pin now jumps once the map has
  centred it.
- **Verified**: phone (debug): mid-pan one crisp lifted pin over its shadow, no double; after the pan, hover
  goes on; switching pins (the old one back to normal, the new one hovering), deselecting by a tap on the map,
  zooming with the button while selected. Profile, 2 runs: map pan and zoom 0 % janky in both apart from one
  56 ms raster frame in the first zoom run (gone in the second, worst 4.8 ms); map_focus 0.4 % and 1.5 %
  (first frames and one 14 ms build; the pre-M-02 baseline was 1.8 %, 11.1 ms); capsule_dialog only its first
  frames. Tests: `selected_pin_test.dart` (motion held and resumed in the same pose, landing, the map's posed
  pin and shadow, the bitmaps drawn), gates green.

## 2026-10-18, M-02 follow-up 4: no blink when a finger touches or lifts, one shadow (`70a9983`)
- **Owner**: touching the map (press, hold, move, lift) made the selected pin blink; then the shadow still
  flashed on clicks. Also: the hover pauses while a finger rests on the map (kept: the owner's choice, see below).
- **How it was found**: `tool/dev/frames.dart` (new) reads `screenrecord --output-format=frames` (raw frames,
  every composition) and lays out the frames that changed, or prints where the pin's outline is in each; the
  owner's own video was read with ffmpeg (imageio-ffmpeg in a venv under `build/`, nothing installed system-wide).
  One frame with only the shadow and no pin, on a touch and on a lift.
- **Causes and fixes**:
  - On a touch the capsule's own marker was changed to the posed pin; a changed marker gets its bitmap again
    and is missing until it has loaded. Now the capsule's marker stays as it is (hidden) and the posed pin is a
    marker of its own, added and removed; the frozen overlay stays 100 ms longer while it loads.
  - On a lift the overlay was built again and its picture came a frame after its shadow. Now it stays built
    and is only not painted while the map draws the pin.
  - The overlay's shadow and the map's shadow overlapped during each hand-over; two see-through shadows
    flashed darker. Now there is one shadow, a marker of the map's, from the selection until the pin starts
    landing; it never changes. It no longer grows and shrinks with the jump.
  - After landing the capsule's marker changes back (a reload): the overlay waits 250 ms over it (the map is
    still).
- **Kept**: the hover pauses while a finger is on the map. The map draws the pin then and cannot animate it;
  handing over on the touch, while the map is still, is what keeps the pin from trailing or doubling when a
  drag starts (the owner chose this over a short lag at every drag start, or no continuous hover).
- **Verified**: owner on the phone (press, hold, move, lift: no blink); frame recordings of presses and drags
  before the fix showed the one-frame gap, none in the owner's check after. Tests: `selected_pin_test.dart`
  (the capsule's marker unchanged while posed, the posed pin a marker of its own, the same shadow in both
  modes). Gates green except the known flaky `capsule_creation_test.dart:151` (passes alone).

## 2026-10-18, M-03 + M-04 Capsules come onto the map in groups; bubbles open and close (`172665e`)
- **Was**: on the first open the pins dropped in over a blank map, bit by bit as their lists arrived; zooming
  swapped every marker at once, and bubbles blinked out and back on every zoom.
- **Changed**: `MarkerChoreography` (+ `MarkerChoreographyOverlay`) decides what comes and goes: on the first
  open, once the map has drawn (its first stop + 450 ms), the pins pop in ring by ring from the middle of the
  screen; zooming in, each bubble shrinks away and its capsules fly out to their spots, group after group, nearest
  the middle first; zooming out, pins fly into their new bubble, which pops in. Flutter draws the moving ones over
  the still map; the map gets the markers only when everything has landed (adding markers holds up Android's
  main thread, where Flutter's frames come from), under the still sprites, which go once the map has drawn
  them. A finger on the map lands everything at once, still drawn until the map has it. Reduced motion, the
  selected pin and pins off screen: no show.
- **Causes fixed on the way** (from the owner's two videos, read frame by frame, and `tool/dev/frames.dart`):
  - Every marker's bitmap was the 457 px artwork: the map decoded it for every marker it added, which froze the
    screen ~200 ms right as the show began. Pins are now drawn once at their size on screen
    (`MarkerIcons._loadPins`); the same pictures are the sprites.
  - A bubble's id held the zoom level and grid cell, so every bubble left and came back on every zoom. The id
    now comes from its capsules (`map_clusters.dart`): the same capsules are the same bubble at any zoom.
  - Markers were swapped while a finger held the map still for a moment (a pinch); now only on a still map.
  - A touch during the show dropped the sprites at once while the map was still drawing the new markers:
    about four blank frames. Now they stand where they land until the map has drawn them.
- **Found, not fixed here (M-11)**: below zoom 12 the map hides the bubbles for the green glow, but the native
  heatmap draws nothing on the owner's phone (built with 1,205 points, no error, also with default colours), so
  far out the map was empty.
- **Verified**: phone, frame recordings: first open (map first, then rings), zoom in and out with the buttons
  (no frame with markers missing), zoom then touch three times (no blink; before the fix the first run blinked);
  the owner's videos for the causes. Profile, 1 run: map pan and zoom 0 % janky, capsule_dialog 0.5 %,
  map_focus 1.2 % (its first frames; 1.8 % before M-02). Tests: `marker_choreography_test.dart` (rings from the
  middle, bubbles opening and closing, nothing on the map until all landed, a touch lands everything still
  drawn, reduced motion, a capsule gone before landing). Gates green.

## 2026-10-18, M-11 A real heatmap far out; the map follows a pinch while the fingers are down
- **Owner**: far out the map was empty (the numbers vanished); then, on a first try (bubbles turned into soft
  glows), "that is just the bubbles blurred": the heat must come from every capsule's own place, not the
  grouping, be less saturated, not only green, and not redraw when the map only moves. Then: under a pinch the
  bubbles split, merge and turn into heat only once the fingers lift; it must follow while they are down.
- **Cause of the empty map**: the plugin's native heatmap draws nothing on the owner's phone (built with 1,205
  points, no error, also with the default colours). A tile layer the app draws itself does show.
- **Changed**:
  - `CapsuleHeatmap`: a tile layer the map draws below zoom 12. Heat from every capsule's own place (two in one
    spot count twice), a soft bump each, on a log scale against the busiest 2 % of places; a cool-to-warm ramp of
    the app's colours (blue, green, yellow, orange; no red, it means danger), at most 35 % opaque, colour
    climbing slower than the heat so only real hotspots turn warm. Tiles are drawn in a background isolate;
    the map keeps them, so panning draws nothing again (measured: panning away 5 new edge tiles, back 0).
  - The bump has one size on the ground (about 700 m, at least 3 dp very far out), so every zoom level's tiles
    show the same picture and the swap at a whole zoom number (any small pinch) cannot be seen; no fade-in.
  - The heat keeps the places of every public band seen this session (`MapController.heatCapsules`), so panning
    into a new band never takes heat away or redraws it.
  - Under a finger the markers follow the zoom at once: whenever it crosses a level they are grouped again for
    what is on screen (`MapProjection.toLatLng` for its corners), swapped on the map itself (no flying under a
    finger), the new ones added a dozen every frame from the middle out, the old ones kept until the new ones
    are drawn: never a gap. The buttons and the first open keep the show.
  - The native heatmap, its two colours and the first glow try are gone.
- **Verified**: phone: held one-finger zoom out (pins merged into bubbles before lifting) and in (bubbles split
  before lifting); held across zoom 12 both ways (bubbles to heat and back before lifting); the heat through a
  slow held zoom (scales smoothly, no jump at the base map's level swap); pan far north and back (no redraw
  coming back). Profile: the first live version had map_zoom_in at 5.1 % janky (Android's main thread adding
  ~100 markers at once: 20 to 40 ms waits for a frame surface); adding them a dozen a frame: 0 % (one run),
  2.8 % (one 40 ms frame of 213) in the full run; pan 0 %, capsule_dialog 0.5 %, map_focus 1.5 %. Tests:
  `capsule_heatmap_test.dart` (one capsule faint and cool, a crowd warmer but never solid, every capsule counts,
  the same heat at every level, no tile far from capsules, the same places redraw nothing),
  `map_projection_test.dart` (screen back to place), `marker_choreography_test.dart` (under a finger: a few at a
  time, the old kept until the new are drawn). Gates green except the known flaky `capsule_creation_test.dart`.

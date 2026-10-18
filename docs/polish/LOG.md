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

## 2026-10-18, M-02 follow-up 3: the selected pin stays on its spot while the map moves
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

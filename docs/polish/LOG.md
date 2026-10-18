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

## 2026-10-18, M-02 follow-up: jump, sway and hover instead of a ring
- **Owner**: the green outline clashed with the other pin colours; asked for motion instead (sway, hover, jump).
- **Changed**: no ring. The selected pin jumps off its spot (tip 13 dp up), lands, sways once (7°, −5°, 0° around
  its spot, through the marker's rotation, no new bitmaps) and rests hovering 9 dp above a soft blurred shadow
  that marks the spot, grown to 1.14×, on top of the other pins. Six marker updates in about 330 ms, then it is
  still (no continuous updates). Reduced motion: hovering at once.
- **Verified**: phone (debug): hovering with its shadow while the card is open. Tests updated (jump then land,
  rests upright, within `AppMotion.reveal`, anchored at its spot). Not re-measured in profile: same mechanism as
  the first version (6 marker updates instead of 4).

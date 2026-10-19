# MORNING_SUMMARY.md: no flashing bubbles (mission 3)

Branch `fix/map-flash-ghosts-selection` (from `feature/map-maplibre-polish`; local commits, **not pushed, not
merged**). Nothing deployed, no production data touched: every check ran on the Galaxy S20 FE against the local
Firebase emulators. MapLibre with OpenFreeMap stays the map. Mission 2's summary is in git history (`aced9e8`).

## What was wrong, and what changed
- **The flashing bubbles** had several causes, each measured and fixed:
  - MapLibre faded every newly placed pin and bubble in over 300 ms and faded old ones out at their old places.
    That made the "lighter then solid" frames and the fuzzy green discs. **Turned off.**
  - Pieces landing were drawn twice for a moment (two sources), which doubled the shadow.
  - Moving pieces faded in a tenth of a second on a fast zoom.
  - Above 60 pieces they didn't move at all, hence "only some flash".
  - The changing number in a bubble made the map re-lay out all its icons each time.
- Now one picture holds every pin and bubble. Moving pieces grow and shrink but are never see-through, everything on
  screen moves, and bubble numbers stay fixed while moving.
- **Fast zoom out collapses**: the motion gets shorter (down to about 0.1 s) but is never skipped; capsules fly into
  their bubble at any speed. A flick straight into the heat clears them with the zoom, as you asked before.
- **The selected pin is one marker**: it grows (0.15 s) and rises in place, its shadow with it, and lands exactly on
  its spot. No second copy, no jump at the end.
- **The map's "i"** is now ours: a small disc like the other map buttons, plus a tiny credit line always on the map
  ("OpenFreeMap © OpenMapTiles Data from OpenStreetMap"). Tapping it lists the sources with links, "Improve this
  map" and "Map rendered with MapLibre". The same list is in Settings > About > "Map data and licenses", and the
  licences page now names MapLibre and the map data.

## The numbers (FLASH_FIX.md, PERFORMANCE.md "After 3")
| | Before | Now |
|---|---|---|
| Your recording / our detector | 17 flash flags in 70 s | – |
| Frames with a pin or bubble drawn twice | 27–78 per flow | 0 |
| Frames with a visible one missing, or a leftover | up to 3 per flow | 0 (light) |
| Flash flags per 20 s of zooming (slow / normal / fast) | 0 / 2 / 1 | 0 / 0 / 1 (three runs) |

The one fast flag per run is, in every case I looked at, a real change happening faster than the detector can tell
apart: the bubbles finishing their fade-in as the first pinch leaves the heat, then splitting. One run had a real
glitch: a bubble opened and closed within 30 ms. It didn't come back.

## Your decision
- **The credit line**: always visible (default, my recommendation), or shown for the first 5 seconds of each session
  and then only the "i" (`FeatureFlags.mapCreditCollapses`). OpenStreetMap allows collapsing; OpenMapTiles' licence
  asks for a visible credit, so ask MapTiler before switching.

## Try it (5 minutes)
1. Over central Warsaw, zoom slowly in and out from the heat to the streets: bubbles split and gather; watch for
   flashing or fuzzy leftovers.
2. Flick quickly in and out a few times.
3. With capsules open (zoom 15), flick out fast: they should fly into bubbles, not vanish.
4. Tap a capsule, then tap the map: the pin lands once, in place. Tap one, then another quickly.
5. Tap the "i" bottom left; then Settings > About > "Map data and licenses".
6. Repeat 1–4 in dark mode.

## Weak spots left (BLOCKERS.md)
- Dark mode: one test run counted a few one-frame gaps (light: none). Needs a second run.
- The one-off 30 ms bubble glitch on a fast flick (above).
- Reduced motion was not measured on the phone; by the code, everything switches at once.
- Settings' About page is called "About me" in every language. I spotted it on the way and didn't touch it.

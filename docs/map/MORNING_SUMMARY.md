# MORNING_SUMMARY.md: the MapLibre map, finished (mission 2)

Branch `feature/map-maplibre-polish` (from `feature/map-engine-smoothness`; local commits, **not pushed, not
merged**). Nothing deployed, no production data touched: every check ran on the Galaxy S20 FE against the local
Firebase emulators. Mission 1's summary is in git history (`02fda14`).

## Decided, and open
- Decided by you on 19 Oct: MapLibre with OpenFreeMap tiles is the map; satellite hidden.
- **Open: OpenFreeMap in production.** Free, no key, commercial use allowed, but no service guarantee. My
  recommendation: keep it, and if it ever fails for long, point the same style files at a self-hosted map file
  (Protomaps/OpenMapTiles, only hosting cost) or a paid MapTiler plan. Nothing to do now.

## What changed
- **The abrupt zooms were the phone, not the map.** An earlier test of "reduce motion" left Android's animation
  speed at 0 on your phone; MapLibre's double tap, two-finger tap and zoom coast use Android's animators, so they
  jumped a whole level in one frame. Restored. Now each tap zoom passes through 30–78 steps over about 0.3 s, never
  more than 0.18 of a level at a time (it was one jump). The test rig refuses to measure if this happens again.
- **Bubbles split and merge again**, on the new map: zooming in, a bubble eases up and opens while its capsules fly
  out to their spots on a short arc and settle, its number counting down; zooming out they fly back in and the
  bubble grows under them, counting up. Nearest the middle first; it follows the fingers and can be reversed
  mid-way; with reduced motion it just switches. No translucent ghosts left behind.
- **Heat to bubbles is quick and clean**: the heat thins as the bubbles grow in and is gone as soon as they are
  whole; never all three strong at once, never nothing.
- **Zoom limits**: no more zooming out to a plain ocean; it stops at about a continent.
- **The base map's colours come from the app's palette**: calm water, brand-green parks, soft labels; light and
  dark.
- The card's countdown no longer shows seconds ("281d 14h 19m").
- Found on the way: the map was doing the old Google map's grouping work after every stop, and big data updates
  were parsed on Android's main thread. Both fixed.

## The numbers (PERFORMANCE.md, "After 2")
| | Before (your recording) | Now |
|---|---|---|
| Tap zoom | one jump of a level | 30–78 steps, at most 0.18 of a level each |
| Recording gaps ≥ 100 ms | 8 in 92 s | 0 in every run |
| Flutter janky frames | – | 0–0.4 % (0.8 % with 2,205 capsules) |
| Map scale vs fingers | – | within 0.02 of a level on average |
| Place under the fingers | – | stays put (0 dp drift) |
| Heat layer changes, markers re-added | 0 | 0 |

## Try it (5 minutes)
1. Zoom out slowly from a street to the country and back: bubbles gather and open with their capsules flying.
2. Double tap, and tap with two fingers: smooth, about a third of a second.
3. Pinch quickly in and out; turn the map with two fingers.
4. Tap a capsule (card, raised pin); tap a bubble (fits its capsules).
5. Switch a filter, then the theme (dark map).

## Weak spots left (BLOCKERS.md)
- Nothing ran on iOS.
- Areas never seen show a blurry map for a moment while their tiles load; nothing is downloaded ahead.
- One run had a single small hitch in a button zoom right after the app started; not seen again.
- The first open no longer has the "capsules pop in, in rings" show; the pins simply appear.
